module stage2_decode #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input logic drop_instruction_decode_stage,
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
    decoded_instruction = 0;
    case (undecoded_instruction.opcode)
      OP_ARITHMETIC_IMMEDIATE, OP_LOAD, OP_JALR: begin  // I-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.immediate = {{20{undecoded_instruction.instr.i_type.immediate[11]}}, undecoded_instruction.instr.i_type.immediate};
        decoded_instruction.rs1 = undecoded_instruction.instr.i_type.rs1;
        decoded_instruction.funct3 = undecoded_instruction.instr.i_type.funct3;
        decoded_instruction.rd = undecoded_instruction.instr.i_type.rd;
      end
      OP_ARITHMETIC: begin  // R-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.immediate = 0;
        decoded_instruction.rd = undecoded_instruction.instr.r_type.rd;
        decoded_instruction.funct3 = undecoded_instruction.instr.r_type.funct3;
        decoded_instruction.rs1 = undecoded_instruction.instr.r_type.rs1;
        decoded_instruction.rs2 = undecoded_instruction.instr.r_type.rs2;
        decoded_instruction.funct7 = undecoded_instruction.instr.r_type.funct7;
      end
      OP_BRANCH: begin  // B-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.immediate = {
          {19{undecoded_instruction.instr.b_type.immediate_12}},
          undecoded_instruction.instr.b_type.immediate_12,
          undecoded_instruction.instr.b_type.immediate_11,
          undecoded_instruction.instr.b_type.immediate_10_5,
          undecoded_instruction.instr.b_type.immediate_4_1,
          1'b0
        };
        decoded_instruction.rs2 = undecoded_instruction.instr.b_type.rs2;
        decoded_instruction.rs1 = undecoded_instruction.instr.b_type.rs1;
        decoded_instruction.funct3 = undecoded_instruction.instr.b_type.funct3;

      end
      OP_JAL: begin  // J-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.immediate = {
          {11{undecoded_instruction.instr.j_type.immediate_20}},
          undecoded_instruction.instr.j_type.immediate_20,
          undecoded_instruction.instr.j_type.immediate_19_12,
          undecoded_instruction.instr.j_type.immediate_11,
          undecoded_instruction.instr.j_type.immediate_10_1,
          1'b0
        };
        decoded_instruction.rd = undecoded_instruction.instr.j_type.rd;
      end

      OP_STORE: begin  // S-TYPE
        decoded_instruction.opcode = undecoded_instruction.opcode;
        decoded_instruction.immediate = {{20{undecoded_instruction.instr.s_type.immediate_11_5[6]}}, undecoded_instruction.instr.s_type.immediate_11_5, undecoded_instruction.instr.s_type.immediate_4_0};
        decoded_instruction.rs2 = undecoded_instruction.instr.s_type.rs2;
        decoded_instruction.rs1 = undecoded_instruction.instr.s_type.rs1;
        decoded_instruction.funct3 = undecoded_instruction.instr.s_type.funct3;
      end
      default: begin
      end
    endcase
  end


  always_comb begin
    read_address_1 = 0;
    read_address_2 = 0;
    read_enable = 0;

    case (decoded_instruction.opcode)
      OP_ARITHMETIC_IMMEDIATE, OP_JALR, OP_ARITHMETIC: begin
        read_address_1 = decoded_instruction.rs1;
        read_enable = 1;
      end
      OP_STORE: begin
        read_address_1 = decoded_instruction.rs1;
        read_address_2 = decoded_instruction.rs2;
        read_enable = 1;
      end

      OP_BRANCH: begin
        read_address_1 = decoded_instruction.rs1;
        read_address_2 = decoded_instruction.rs2;
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

  assign registerport_read_1.enable  = read_enable;
  assign registerport_read_1.address = read_address_1;

  assign registerport_read_2.enable  = read_enable;
  assign registerport_read_2.address = read_address_2;

  // Flops
  always_ff @(posedge clk) begin
    if (rst) begin
      axis_decode_to_execute.tvalid <= 0;
    end else begin
      axis_decode_to_execute.tvalid <= 0;
      if (axis_fetch_to_decode.tvalid && !drop_instruction_decode_stage) begin
        axis_decode_to_execute.tvalid <= 1;
        axis_decode_to_execute.tdata.program_counter <= axis_fetch_to_decode.tdata.program_counter;
        axis_decode_to_execute.tdata.decoded_instruction <= decoded_instruction;
        axis_decode_to_execute.tdata.branch_taken_prediction <= axis_fetch_to_decode.tdata.branch_taken_prediction;

        axis_decode_to_execute.tdata.rs1_value <= registerport_read_1.data;
        axis_decode_to_execute.tdata.rs2_value <= registerport_read_2.data;
      end
    end
  end


  assign axis_fetch_to_decode.tready = axis_decode_to_execute.tready;


endmodule
