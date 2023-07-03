import common::*;

module execution_unit
(
    input logic clk,
    input logic [REGISTER_WIDTH-1:0] rs1_value,
    input logic [REGISTER_WIDTH-1:0] rs2_value,
    input instruction_t decoded_instruction,
    output logic [REGISTER_WIDTH-1:0] alu_result
);


logic [REGISTER_WIDTH-1:0] alu_input2;
logic [REGISTER_WIDTH-1:0] immediate;

always_comb begin
    case (decoded_instruction.opcode)
        I_TYPE: begin
            case (decoded_instruction.instr.i_type.funct3)
                SLLI: alu_input2 = REGISTER_WIDTH'(decoded_instruction.instr.i_type.imm[4:0]);
                SRLI_OR_SRAI: alu_input2 = REGISTER_WIDTH'(decoded_instruction.instr.i_type.imm[4:0]);
                default: alu_input2 = REGISTER_WIDTH'(decoded_instruction.instr.i_type.imm);
            endcase
        end
        R_TYPE: begin
            alu_input2 = rs2_value;
        end
        default: alu_input2 = 0;
    endcase
end

    // Instantiate the ALU
arithmetic_logic_unit alu_inst (
    .input1(rs1_value),
    .input2(alu_input2),
    .decoded_instruction(decoded_instruction),
    .result(alu_result)
);


endmodule