import common::*;

module decode #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] instruction,
    output instruction_t decoded_instruction
);

  instruction_undecoded_t undecoded_instruction;

  assign undecoded_instruction = instruction;

  always_comb begin
    case (undecoded_instruction.opcode)
        OPCODE_ARITHMETIC_IMMEDIATE | OPCODE_LOAD | OPCODE_JALR: begin // I-TYPE
            decoded_instruction = undecoded_instruction;
        end
        OPCODE_ARITHMETIC: begin // R-TYPE
            decoded_instruction = undecoded_instruction;
        end
        OPCODE_BRANCH: begin // B-TYPE
            decoded_instruction.opcode = undecoded_instruction.opcode;
            decoded_instruction.instr.b_type.immediate = {undecoded_instruction.instr.b_type.immediate_12, undecoded_instruction.instr.b_type.immediate_11, undecoded_instruction.instr.b_type.immediate_10_5, undecoded_instruction.instr.b_type.immediate_4_1};
            decoded_instruction.instr.b_type.rs2 = undecoded_instruction.instr.b_type.rs2;
            decoded_instruction.instr.b_type.rs1 = undecoded_instruction.instr.b_type.rs1;
            decoded_instruction.instr.b_type.funct3 = undecoded_instruction.instr.b_type.funct3;

        end
        OPCODE_JAL: begin // J-TYPE
            decoded_instruction.opcode = undecoded_instruction.opcode;
            decoded_instruction.instr.j_type.immediate = {undecoded_instruction.instr.j_type.immediate_20, undecoded_instruction.instr.j_type.immediate_19_12, undecoded_instruction.instr.j_type.immediate_11, undecoded_instruction.instr.j_type.immediate_10_1};
            decoded_instruction.instr.j_type.rd = undecoded_instruction.instr.j_type.rd;
        end

        OPCODE_STORE: begin // S-TYPE
            decoded_instruction.opcode = undecoded_instruction.opcode;
            decoded_instruction.instr.s_type.immediate = {undecoded_instruction.instr.s_type.immediate_11_5, undecoded_instruction.instr.s_type.immediate_4_0};
            decoded_instruction.instr.s_type.rs2 = undecoded_instruction.instr.s_type.rs2;
            decoded_instruction.instr.s_type.rs1 = undecoded_instruction.instr.s_type.rs1;
            decoded_instruction.instr.s_type.funct3 = undecoded_instruction.instr.s_type.funct3;
        end
        default: decoded_instruction = undecoded_instruction;
    endcase
end

endmodule
