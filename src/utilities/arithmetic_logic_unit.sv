import common::*;

module arithmetic_logic_unit (
    input logic [REGISTER_WIDTH-1:0] input1,
    input logic [REGISTER_WIDTH-1:0] input2,
    input instruction_t decoded_instruction,
    output logic [REGISTER_WIDTH-1:0] result
);

  always_comb begin
    result = 0;  // default value
    case (decoded_instruction.opcode)
      OP_ARITHMETIC_IMMEDIATE: begin  // I-TYPE
        case (decoded_instruction.instr.i_type.funct3)
          ADDI_OR_JAL: result = input1 + input2;
          XORI: result = input1 ^ input2;
          ORI: result = input1 | input2;
          ANDI: result = input1 & input2;
          SLLI: result = input1 << input2[4:0];
          SRLI_OR_SRAI: result = input1 >> input2[4:0];
          SLTI: result = (input1 < input2) ? 1 : 0;
          SLTUI: result = (input1 < input2) ? 1 : 0;
          default: result = 0;
        endcase
      end
      OP_ARITHMETIC: begin  // R-TYPE
        case (decoded_instruction.instr.i_type.funct3)
          ADD_OR_SUB: result = input1 + input2;
          XOR: result = input1 ^ input2;
          OR: result = input1 | input2;
          AND: result = input1 & input2;
          SLL: result = input1 << input2[4:0];
          SRL_OR_SRA: result = input1 >> input2[4:0];
          SLT: result = (input1 < input2) ? 1 : 0;
          SLTU: result = (input1 < input2) ? 1 : 0;
          default: result = 0;
        endcase
      end
      // Add cases for other opcode values here
      default: result = 0;
    endcase
  end

endmodule
