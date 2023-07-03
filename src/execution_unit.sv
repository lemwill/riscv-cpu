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

// If the operation is ADDI, use immediate as the second operand. Otherwise, use rs1_value.
always_comb begin
    if (decoded_instruction.opcode == I_TYPE && decoded_instruction.funct3 == ADDI) begin
        immediate = REGISTER_WIDTH'(decoded_instruction.immediate);
        alu_input2 = immediate;
    end else begin
        alu_input2 = rs1_value;
    end
end

    // Instantiate the ALU
arithmetic_logic_unit alu_inst (
    .input1(rs1_value),
    .input2(alu_input2),
    .decoded_instruction(decoded_instruction),
    .result(alu_result)
);


endmodule