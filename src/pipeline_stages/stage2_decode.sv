module stage2_decode #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic rst,
    Axis.in axis_fetch_to_decode,
    Axis.out axis_decode_to_execute,
    MemoryInterface.read_out registerport_read_1,
    MemoryInterface.read_out registerport_read_2
);

  instruction_undecoded_t undecoded_instruction;

  assign undecoded_instruction = axis_fetch_to_decode.tdata.instruction;
  instruction_t decoded_instruction;
  logic read_enable;
  logic [$clog2(REGISTER_DEPTH)-1:0] read_address_1;
  logic [$clog2(REGISTER_DEPTH)-1:0] read_address_2;

  always_comb begin
    case (undecoded_instruction.opcode)
      OPCODE_ARITHMETIC_IMMEDIATE | OPCODE_LOAD | OPCODE_JALR: begin  // I-TYPE
        decoded_instruction = undecoded_instruction;
      end
      OPCODE_ARITHMETIC: begin  // R-TYPE
        decoded_instruction = undecoded_instruction;
      end
      OPCODE_BRANCH: begin  // B-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.instr.b_type.immediate = {
          undecoded_instruction.instr.b_type.immediate_12,
          undecoded_instruction.instr.b_type.immediate_11,
          undecoded_instruction.instr.b_type.immediate_10_5,
          undecoded_instruction.instr.b_type.immediate_4_1
        };
        decoded_instruction.instr.b_type.rs2 = undecoded_instruction.instr.b_type.rs2;
        decoded_instruction.instr.b_type.rs1 = undecoded_instruction.instr.b_type.rs1;
        decoded_instruction.instr.b_type.funct3 = undecoded_instruction.instr.b_type.funct3;

      end
      OPCODE_JAL: begin  // J-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.instr.j_type.immediate = {
          undecoded_instruction.instr.j_type.immediate_20,
          undecoded_instruction.instr.j_type.immediate_19_12,
          undecoded_instruction.instr.j_type.immediate_11,
          undecoded_instruction.instr.j_type.immediate_10_1
        };
        decoded_instruction.instr.j_type.rd = undecoded_instruction.instr.j_type.rd;
      end

      OPCODE_STORE: begin  // S-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.instr.s_type.immediate = {
          undecoded_instruction.instr.s_type.immediate_11_5,
          undecoded_instruction.instr.s_type.immediate_4_0
        };
        decoded_instruction.instr.s_type.rs2 = undecoded_instruction.instr.s_type.rs2;
        decoded_instruction.instr.s_type.rs1 = undecoded_instruction.instr.s_type.rs1;
        decoded_instruction.instr.s_type.funct3 = undecoded_instruction.instr.s_type.funct3;
      end
      default: decoded_instruction = undecoded_instruction;
    endcase
  end


  always_comb begin
    read_address_1 = 0;
    read_address_2 = 0;
    read_enable = 0;

    case (decoded_instruction.opcode)
      OPCODE_ARITHMETIC_IMMEDIATE, OPCODE_JALR, OPCODE_ARITHMETIC: begin
        read_address_1 = decoded_instruction.instr.i_type.rs1;
        read_enable = 1;
      end
      OPCODE_STORE: begin
        read_address_1 = decoded_instruction.instr.s_type.rs1;
        read_address_2 = decoded_instruction.instr.s_type.rs2;
        read_enable = 1;
      end

      OPCODE_BRANCH: begin
        read_address_1 = decoded_instruction.instr.b_type.rs1;
        read_address_2 = decoded_instruction.instr.b_type.rs2;
        read_enable = 1;
      end

      default: begin
        // Default case to handle other opcodes
        read_address_1 = 0;
        read_address_2 = 0;
        read_enable = 0;
      end
    endcase
  end

  assign registerport_read_1.enable = read_enable;
  assign registerport_read_1.address = read_address_1;

  assign registerport_read_2.enable = read_enable;
  assign registerport_read_2.address = read_address_2;



  assign axis_decode_to_execute.tdata.program_counter = axis_fetch_to_decode.tdata.program_counter;
  assign axis_decode_to_execute.tdata.decoded_instruction = decoded_instruction;
  assign axis_decode_to_execute.tvalid = 1;
  //assign axis_fetch_to_decode.tready = axis_decode_to_execute.tready;


endmodule
