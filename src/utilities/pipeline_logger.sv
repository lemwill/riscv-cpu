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

  localparam int FETCH_WIDTH = 15;
  localparam int DECODE_WIDTH = 40;
  localparam int EXECUTE_WIDTH = 40;
  localparam int MEMORY_WIDTH = 40;
  localparam int WRITEBACK_WIDTH = 40;

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

  function string get_instruction_description(common::instruction_t instruction);
    case (instruction.opcode)
      common::OP_LUI:
      return $sformatf("LUI x%0d=0x%0h", instruction.rd, instruction.immediate.u_type);
      common::OP_AUIPC:
      return $sformatf("AUIPC x%0d=PC+0x%0h", instruction.rd, instruction.immediate.u_type);
      common::OP_JAL:
      return $sformatf("JAL x%0d=PC+4;PC=PC+0x%0h", instruction.rd, instruction.immediate.j_type);
      common::OP_JALR:
      return $sformatf(
          "JALR x%0d=PC+4;PC=(x%0d+0x%0h)&~1",
          instruction.rd,
          instruction.rs1,
          instruction.immediate.i_type
      );
      common::OP_BRANCH:
      return $sformatf(
          "BRANCH if (x%0d%sx%0d) PC=PC+0x%0h",
          instruction.rs1,
          branch_op(
              instruction.funct3.b_type
          ),
          instruction.rs2,
          instruction.immediate.b_type
      );
      common::OP_LOAD:
      return $sformatf(
          "LOAD x%0d=Mem[x%0d+0x%0h]", instruction.rd, instruction.rs1, instruction.immediate.i_type
      );
      common::OP_STORE:
      return $sformatf(
          "STORE Mem[x%0d+0x%0h]=x%0d",
          instruction.rs1,
          instruction.immediate.s_type,
          instruction.rs2
      );
      common::OP_ARITHMETIC_IMMEDIATE:
      return arithmetic_imm_desc(
          instruction.funct3.i_type, instruction.rd, instruction.rs1, instruction.immediate.i_type
      );
      common::OP_ARITHMETIC:
      return arithmetic_desc(
          instruction.funct3.r_type,
          instruction.rd,
          instruction.rs1,
          instruction.rs2,
          instruction.funct7
      );
      default: return "UNKNOWN";
    endcase
  endfunction

  function string branch_op(common::BTypeFunct3 funct3);
    case (funct3)
      common::BEQ: return "==";
      common::BNE: return "!=";
      common::BLT: return "<";
      common::BGE: return ">=";
      common::BLTU: return "<u";
      common::BGEU: return ">=u";
      default: return "??";
    endcase
  endfunction

  function string arithmetic_imm_desc(common::ITypeFunct3 funct3, logic [4:0] rd, logic [4:0] rs1,
                                      logic [11:0] imm);
    case (funct3)
      common::ADDI_OR_JAL: return $sformatf("ADDI x%0d=x%0d+%0d", rd, rs1, imm);
      common::XORI: return $sformatf("XORI x%0d=x%0d^%0d", rd, rs1, imm);
      common::ORI: return $sformatf("ORI x%0d=x%0d|%0d", rd, rs1, imm);
      common::ANDI: return $sformatf("ANDI x%0d=x%0d&%0d", rd, rs1, imm);
      common::SLLI: return $sformatf("SLLI x%0d=x%0d<<%0d", rd, rs1, imm[4:0]);
      common::SRLI_OR_SRAI: return $sformatf("SRLI x%0d=x%0d>>%0d", rd, rs1, imm[4:0]);
      common::SLTI: return $sformatf("SLTI x%0d=(x%0d<%0d)?1:0", rd, rs1, imm);
      common::SLTUI: return $sformatf("SLTUI x%0d=(x%0d<u%0d)?1:0", rd, rs1, imm);
      default: return "UNKNOWN";
    endcase
  endfunction

  function string arithmetic_desc(common::RTypeFunct3 funct3, logic [4:0] rd, logic [4:0] rs1,
                                  logic [4:0] rs2, logic [6:0] funct7);
    case (funct3)
      common::ADD_OR_SUB:
      return funct7[5] ? $sformatf(
          "SUB x%0d=x%0d-x%0d", rd, rs1, rs2
      ) : $sformatf(
          "ADD x%0d=x%0d+x%0d", rd, rs1, rs2
      );
      common::XOR: return $sformatf("XOR x%0d=x%0d^x%0d", rd, rs1, rs2);
      common::OR: return $sformatf("OR x%0d=x%0d|x%0d", rd, rs1, rs2);
      common::AND: return $sformatf("AND x%0d=x%0d&x%0d", rd, rs1, rs2);
      common::SLL: return $sformatf("SLL x%0d=x%0d<<x%0d", rd, rs1, rs2);
      common::SRL_OR_SRA:
      return funct7[5] ? $sformatf(
          "SRA x%0d=x%0d>>x%0d", rd, rs1, rs2
      ) : $sformatf(
          "SRL x%0d=x%0d>>x%0d", rd, rs1, rs2
      );
      common::SLT: return $sformatf("SLT x%0d=(x%0d<x%0d)?1:0", rd, rs1, rs2);
      common::SLTU: return $sformatf("SLTU x%0d=(x%0d<u x%0d)?1:0", rd, rs1, rs2);
      default: return "UNKNOWN";
    endcase
  endfunction

  function string pad_string(string str, int width);
    string padded_str;
    if (str.len() < width) begin
      padded_str = {str, {" ", width - str.len()}};
    end else begin
      padded_str = str.substr(0, width - 1);
    end
    return padded_str;
  endfunction

  string fetch_buffer;
  string decode_buffer;
  string execute_buffer;
  string memory_buffer;
  string writeback_buffer;
  int cycle_count;

  always_ff @(posedge clk or posedge rst) begin
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
      cycle_count++;

      // Fetch stage
      if (axis_fetch_to_decode.tvalid && axis_fetch_to_decode.tready) begin
        fetch_buffer = $sformatf("PC:%h", axis_fetch_to_decode.tdata.program_counter);
      end else begin
        fetch_buffer = "...";
      end

      // Decode stage
      if (axis_decode_to_execute.tvalid && axis_decode_to_execute.tready) begin
        decode_buffer =
            get_instruction_description(axis_decode_to_execute.tdata.decoded_instruction);
      end else begin
        decode_buffer = "...";
      end

      // Execute stage
      if (axis_execute_to_memory.tvalid && axis_execute_to_memory.tready) begin
        execute_buffer = $sformatf(
            "%s,Res:%h",
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
        memory_buffer =
            get_instruction_description(axis_memory_to_writeback.tdata.decoded_instruction);
        if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_LOAD) begin
          memory_buffer =
              $sformatf("LOAD Addr:%0h,Data:%0d", sramport_data.address, sramport_data.read_data);
        end else if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_STORE) begin
          memory_buffer =
              $sformatf("STORE mem[%0h]=%0d", sramport_data.address, sramport_data.write_data);
        end
      end else begin
        memory_buffer = "...";
      end

      // Writeback stage
      if (axis_memory_to_writeback.tvalid && axis_memory_to_writeback.tready) begin
        writeback_buffer =
            get_instruction_description(axis_memory_to_writeback.tdata.decoded_instruction);
        if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_LOAD || axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_ARITHMETIC_IMMEDIATE || axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_ARITHMETIC) begin
          writeback_buffer =
              $sformatf("%s,Data:%h", writeback_buffer, axis_memory_to_writeback.tdata.alu_result);
        end
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
