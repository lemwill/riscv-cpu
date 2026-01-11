module pipeline_logger #(
    parameter integer NUM_COLORS = 8
) (
    input logic clk,
    input logic rst,
    Axis.monitor axis_fetch_to_decode,
    Axis.monitor axis_decode_to_execute,
    Axis.monitor axis_execute_to_memory,
    Axis.monitor axis_memory_to_writeback,
    MemoryInterfaceSinglePort.master sramport_data
);

  typedef enum logic [2:0] {
    COLOR_RED     = 3'b000,
    COLOR_GREEN   = 3'b001,
    COLOR_BLUE    = 3'b010,
    COLOR_YELLOW  = 3'b011,
    COLOR_MAGENTA = 3'b100,
    COLOR_CYAN    = 3'b101,
    COLOR_WHITE   = 3'b110,
    COLOR_BLACK   = 3'b111
  } color_t;

  color_t instruction_colors[0:NUM_COLORS-1];

  integer log_file;
  string fetch_buffer = "";
  string decode_buffer = "";
  string execute_buffer = "";
  string memory_buffer = "";
  string writeback_buffer = "";

  localparam int FETCH_WIDTH = 15;
  localparam int DECODE_WIDTH = 40;
  localparam int EXECUTE_WIDTH = 40;
  localparam int MEMORY_WIDTH = 40;
  localparam int WRITEBACK_WIDTH = 40;

  int cycle_count;

  RegisterValue sramport_data_write_data_q;
  logic [MEM_ADDRESS_WIDTH-1:0] sramport_data_address_q;

  initial begin
    instruction_colors[0] = COLOR_RED;
    instruction_colors[1] = COLOR_GREEN;
    instruction_colors[2] = COLOR_BLUE;
    instruction_colors[3] = COLOR_YELLOW;
    instruction_colors[4] = COLOR_MAGENTA;
    instruction_colors[5] = COLOR_CYAN;
    instruction_colors[6] = COLOR_WHITE;
    instruction_colors[7] = COLOR_BLACK;

    log_file = $fopen("pipeline_log.txt", "w");
    if (log_file == 0) begin
      $fatal("Failed to open log file.");
    end
    // Print column headers
    $fwrite(log_file, "%-6s %-15s %-40s %-40s %-40s %-40s\n", "Cycle", "FETCH", "DECODE",
            "EXECUTE", "MEMORY", "WRITEBACK");
  end


  function string get_register_name(logic [4:0] reg_num);
    case (reg_num)
      5'd0: get_register_name = "zero";
      5'd1: get_register_name = "ra";
      5'd2: get_register_name = "sp";
      5'd3: get_register_name = "gp";
      5'd4: get_register_name = "tp";
      5'd5: get_register_name = "t0";
      5'd6: get_register_name = "t1";
      5'd7: get_register_name = "t2";
      5'd8: get_register_name = "s0";  // Also known as fp
      5'd9: get_register_name = "s1";
      5'd10: get_register_name = "a0";
      5'd11: get_register_name = "a1";
      5'd12: get_register_name = "a2";
      5'd13: get_register_name = "a3";
      5'd14: get_register_name = "a4";
      5'd15: get_register_name = "a5";
      5'd16: get_register_name = "a6";
      5'd17: get_register_name = "a7";
      5'd18: get_register_name = "s2";
      5'd19: get_register_name = "s3";
      5'd20: get_register_name = "s4";
      5'd21: get_register_name = "s5";
      5'd22: get_register_name = "s6";
      5'd23: get_register_name = "s7";
      5'd24: get_register_name = "s8";
      5'd25: get_register_name = "s9";
      5'd26: get_register_name = "s10";
      5'd27: get_register_name = "s11";
      5'd28: get_register_name = "t3";
      5'd29: get_register_name = "t4";
      5'd30: get_register_name = "t5";
      5'd31: get_register_name = "t6";
      default: get_register_name = $sformatf("x%0d", reg_num);
    endcase
  endfunction


  // Function to retrieve the instruction name (mnemonic)
  function string get_instruction_name(common::instruction_t instruction);
    case (instruction.opcode)
      common::OP_LUI: return "LUI";
      common::OP_AUIPC: return "AUIPC";
      common::OP_JAL: return "JAL";
      common::OP_JALR: return "JALR";
      common::OP_BRANCH: return "BRANCH";
      common::OP_LOAD: return "LOAD";
      common::OP_STORE: return "STORE";
      common::OP_ARITHMETIC_IMMEDIATE: return "ARITH_IMM";
      common::OP_ARITHMETIC: return "ARITH";
      default: begin
        return "UNKNOWN";
      end
    endcase
  endfunction

  // Function to retrieve the instruction subname based on opcode and funct fields
  function string get_instruction_subname(common::instruction_t instruction);
    string name;
    name = get_instruction_name(instruction);
    case (instruction.opcode)
      common::OP_BRANCH: begin
        case (instruction.funct3)
          common::BEQ:  return "BEQ";
          common::BNE:  return "BNE";
          common::BLT:  return "BLT";
          common::BGE:  return "BGE";
          common::BLTU: return "BLTU";
          common::BGEU: return "BGEU";
          default:      return "BR_UNKNOWN";
        endcase
      end
      common::OP_ARITHMETIC_IMMEDIATE: begin
        case (instruction.funct3.i_type)
          common::ADDI_OR_JAL:  return "ADDI";
          common::XORI:         return "XORI";
          common::ORI:          return "ORI";
          common::ANDI:         return "ANDI";
          common::SLLI:         return "SLLI";
          common::SRLI_OR_SRAI: return "SRLI/SRAI";
          common::SLTI:         return "SLTI";
          common::SLTUI:        return "SLTUI";
          default:              return {"ARITH_IMM_UNKNOWN: ", get_instruction_name(instruction)};
        endcase
      end
      common::OP_ARITHMETIC: begin
        case (instruction.funct3.r_type)
          common::ADD_OR_SUB: begin
            if (instruction.funct7[5]) return "SUB";
            else return "ADD";
          end
          common::XOR:  return "XOR";
          common::OR:   return "OR";
          common::AND:  return "AND";
          common::SLL:  return "SLL";
          common::SRL_OR_SRA: begin
            if (instruction.funct7[5]) return "SRA";
            else return "SRL";
          end
          common::SLT:  return "SLT";
          common::SLTU: return "SLTU";
          default:      return {"ARITH_UNKNOWN: ", get_instruction_name(instruction)};
        endcase
      end
      default: return name;  // Return the instruction name if no subname is applicable
    endcase
  endfunction

  // Updated function to get detailed instruction description
  function string get_instruction_description(common::instruction_t instruction);
    string name, subname;
    name = get_instruction_name(instruction);
    subname = get_instruction_subname(instruction);
    case (instruction.opcode)
      common::OP_LUI: return $sformatf("LUI   x%0d=0x%0h", instruction.rd, instruction.immediate);
      common::OP_AUIPC:
      return $sformatf("AUIPC x%0d=PC+0x%0h", instruction.rd, instruction.immediate);
      common::OP_JAL:
      return $sformatf("JAL   x%0d=PC+4; PC=PC+0x%0h", instruction.rd, instruction.immediate);
      common::OP_JALR:
      return $sformatf(
          "JALR  x%0d=PC+4; PC=(x%0d + 0x%0h) & ~1",
          instruction.rd,
          instruction.rs1,
          instruction.immediate
      );
      common::OP_BRANCH:
      return $sformatf(
          "%s if (%s %s %s) PC=PC+0x%0h",
          subname,
          get_register_name(
              instruction.rs1
          ),
          branch_op(
              instruction.funct3.b_type
          ),
          instruction.rs2,
          instruction.immediate
      );
      common::OP_LOAD:
      return $sformatf(
          "LOAD  x%0d=Mem[x%0d + 0x%0h]", instruction.rd, instruction.rs1, instruction.immediate
      );
      common::OP_STORE:
      return $sformatf(
          "STORE Mem[x%0d + 0x%0h] = x%0d", instruction.rs1, instruction.immediate, instruction.rs2
      );
      common::OP_ARITHMETIC_IMMEDIATE:
      return $sformatf(
          "%s x%0d = x%0d %s %0d",
          subname,  // e.g., "ADDI"
          instruction.rd,
          instruction.rs1,
          (subname == "ADDI" || subname == "XORI" || subname == "ORI" || subname == "ANDI" ||
           subname == "SLLI" || subname == "SRLI/SRAI" || subname == "SLTI" || subname == "SLTUI") ? 
             (subname == "SRLI/SRAI" ? ">>" : 
              (subname == "SLLI" ? "<<" : 
               (subname == "ADDI" || subname == "SLTI" || subname == "SLTUI") ? "+" :
               (subname == "XORI" ? "^" :
                (subname == "ORI" ? "|" : 
                 (subname == "ANDI" ? "&" : "?"))))) : "?",
          instruction.immediate
      );
      common::OP_ARITHMETIC:
      return $sformatf(
          "%s %s = %s %s %s",
          subname,
          get_register_name(
              instruction.rd
          ),
          get_register_name(
              instruction.rs1
          ),
          (subname == "ADD" || subname == "SUB") ? "+" :
                (subname == "XOR") ? "^" :
                (subname == "OR") ? "|" :
                (subname == "AND") ? "&" :
                (subname == "SLL") ? "<<" :
                (subname == "SRL") ? ">>" :
                (subname == "SRA") ? ">>>" :
                (subname == "SLT") ? "<" :
                (subname == "SLTU") ? "<u" : "?",
          get_register_name(
              instruction.rs2
          )
      );
      default: return $sformatf("%s", name);
    endcase
  endfunction

  function string branch_op(common::BTypeFunct3 funct3);
    case (funct3)
      common::BEQ:  return "==";
      common::BNE:  return "!=";
      common::BLT:  return "<";
      common::BGE:  return ">=";
      common::BLTU: return "<u";
      common::BGEU: return ">=u";
      default:      return "??";
    endcase
  endfunction

  function string arithmetic_imm_desc(common::ITypeFunct3 funct3, logic [4:0] rd, logic [4:0] rs1,
                                      logic [31:0] imm);
    case (funct3)
      common::ADDI_OR_JAL:
      return $sformatf("ADDI  %s = %s + %0d", get_register_name(rd), get_register_name(rs1), imm);
      common::XORI:
      return $sformatf("XORI  %s = %s ^ %0d", get_register_name(rd), get_register_name(rs1), imm);
      common::ORI:
      return $sformatf("ORI   %s = %s | %0d", get_register_name(rd), get_register_name(rs1), imm);
      common::ANDI:
      return $sformatf("ANDI  %s = %s & %0d", get_register_name(rd), get_register_name(rs1), imm);
      common::SLLI:
      return $sformatf(
          "SLLI  %s = %s << %0d", get_register_name(rd), get_register_name(rs1), imm[4:0]
      );
      common::SRLI_OR_SRAI:
      return $sformatf(
          "SRLI/SRAI %s = %s >> %0d", get_register_name(rd), get_register_name(rs1), imm[4:0]
      );
      common::SLTI:
      return $sformatf(
          "SLTI  %s = (%s < %0d) ? 1 : 0", get_register_name(rd), get_register_name(rs1), imm
      );
      common::SLTUI:
      return $sformatf(
          "SLTUI %s = (%s <u %0d) ? 1 : 0", get_register_name(rd), get_register_name(rs1), imm
      );
      default: return "UNKNOWN";
    endcase
  endfunction

  function string arithmetic_desc(common::RTypeFunct3 funct3, logic [4:0] rd, logic [4:0] rs1,
                                  logic [4:0] rs2, logic [6:0] funct7);
    string subname;
    // Determine subname based on funct3 and funct7
    case (funct3)
      common::ADD_OR_SUB: begin
        if (funct7[5]) subname = "SUB";
        else subname = "ADD";
        return $sformatf(
            "%s %s = %s + %s",
            subname,
            get_register_name(
                rd
            ),
            get_register_name(
                rs1
            ),
            get_register_name(
                rs2
            )
        );
      end
      common::XOR:
      return $sformatf(
          "XOR  %s = %s ^ %s", get_register_name(rd), get_register_name(rs1), get_register_name(rs2)
      );
      common::OR:
      return $sformatf(
          "OR   %s = %s | %s", get_register_name(rd), get_register_name(rs1), get_register_name(rs2)
      );
      common::AND:
      return $sformatf(
          "AND  %s = %s & %s", get_register_name(rd), get_register_name(rs1), get_register_name(rs2)
      );
      common::SLL:
      return $sformatf(
          "SLL  %s = %s << %s",
          get_register_name(
              rd
          ),
          get_register_name(
              rs1
          ),
          get_register_name(
              rs2
          )
      );
      common::SRL_OR_SRA: begin
        if (funct7[5]) subname = "SRA";
        else subname = "SRL";
        return $sformatf(
            "%s  %s = %s >> %s",
            subname,
            get_register_name(
                rd
            ),
            get_register_name(
                rs1
            ),
            get_register_name(
                rs2
            )
        );
      end
      common::SLT:
      return $sformatf(
          "SLT  %s = (%s < %s) ? 1 : 0",
          get_register_name(
              rd
          ),
          get_register_name(
              rs1
          ),
          get_register_name(
              rs2
          )
      );
      common::SLTU:
      return $sformatf(
          "SLTU %s = (%s <u %s) ? 1 : 0",
          get_register_name(
              rd
          ),
          get_register_name(
              rs1
          ),
          get_register_name(
              rs2
          )
      );
      default: return "UNKNOWN";
    endcase
  endfunction


  always_ff @(posedge clk) begin
    if (rst) begin
      // Reset logic
      cycle_count = 0;
      fetch_buffer = "";
      decode_buffer = "";
      execute_buffer = "";
      memory_buffer = "";
      writeback_buffer = "";
      $fclose(log_file);
      log_file = $fopen("pipeline_log.txt", "w");
      if (log_file == 0) begin
        $fatal("Failed to open log file.");
      end
      // Print column headers
      $fwrite(log_file, "%-6s %-15s %-40s %-40s %-40s %-40s\n", "Cycle", "FETCH", "DECODE",
              "EXECUTE", "MEMORY", "WRITEBACK");
    end else begin
      sramport_data_write_data_q <= sramport_data.write_data;
      sramport_data_address_q <= sramport_data.address;
      cycle_count++;

      // Fetch stage
      if (axis_fetch_to_decode.tvalid && axis_fetch_to_decode.tready) begin
        fetch_buffer = $sformatf("PC:%h", axis_fetch_to_decode.tdata.program_counter);
      end else begin
        fetch_buffer = "...";
      end

      // Decode stage
      if (axis_decode_to_execute.tvalid && axis_decode_to_execute.tready) begin
        decode_buffer = $sformatf(
            "%s", get_instruction_description(axis_decode_to_execute.tdata.decoded_instruction));
      end else begin
        decode_buffer = "...";
      end

      // Execute stage
      if (axis_execute_to_memory.tvalid && axis_execute_to_memory.tready) begin
        execute_buffer = $sformatf(
            "%s = %0d",
            get_instruction_description(
              axis_execute_to_memory.tdata.decoded_instruction
            ),
            axis_execute_to_memory.tdata.alu_result
        );
      end else begin
        execute_buffer = "...";
      end

      // Memory stage
      if (axis_memory_to_writeback.tvalid && axis_memory_to_writeback.tready) begin
        // Determine if the instruction is a memory read (LOAD) or write (STORE)
        static
        string
        mem_subname = get_instruction_subname(
            axis_memory_to_writeback.tdata.decoded_instruction
        );
        static
        string
        opcode = get_instruction_description(
            axis_memory_to_writeback.tdata.decoded_instruction
        );
        if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_LOAD || axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_STORE) begin
          memory_buffer = $sformatf(
              "%s, Addr:0x%0h, Data:0x%0h",
              mem_subname,  // e.g., "LOAD" or "STORE"
              sramport_data_address_q,
              (axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_STORE) ? sramport_data_write_data_q : sramport_data.read_data
          );
        end else begin
          // For non-memory operations, only display the opcode
          memory_buffer = opcode;
        end
      end else begin
        memory_buffer = "...";
      end

      // Writeback stage
      // Assuming 'registerport_write' is connected or defined elsewhere
      if (registerport_write.enable) begin
        writeback_buffer =
            $sformatf("Reg:x%0d, Data:%h", registerport_write.address, registerport_write.data);
      end else begin
        writeback_buffer = "...";
      end

      // Write the buffers to the file with fixed column widths
      $fwrite(log_file, "%-6d %-15s %-40s %-40s %-40s %-40s\n", cycle_count, fetch_buffer,
              decode_buffer, execute_buffer, memory_buffer, writeback_buffer);
    end
  end

  final begin
    $fclose(log_file);
  end
endmodule
