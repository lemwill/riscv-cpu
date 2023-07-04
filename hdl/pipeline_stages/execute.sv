import common::*;

module execute
(
    input logic clk,
    input logic [REGISTER_WIDTH-1:0] rs1_value,
    input logic [REGISTER_WIDTH-1:0] rs2_value,
    input instruction_t decoded_instruction,
    input logic [REGISTER_WIDTH-1:0] program_counter,
    output logic [REGISTER_WIDTH-1:0] alu_result,
    output logic branch_taken,
    output logic [REGISTER_WIDTH-1:0] branch_target
);


logic [REGISTER_WIDTH-1:0] alu_input2;
logic [REGISTER_WIDTH-1:0] immediate;


always_comb begin
    branch_taken = 0;
    alu_input2 = 0;
    branch_target = 0;
    case (decoded_instruction.opcode)
        OPCODE_ARITHMETIC_IMMEDIATE : begin // I-TYPE
            alu_input2 = REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
        end
        OPCODE_ARITHMETIC: begin // R-TYPE
            alu_input2 = rs2_value;
        end
        OPCODE_BRANCH: begin // B-TYPE
            case (decoded_instruction.instr.b_type.funct3)
                BEQ: branch_taken = (rs1_value == rs2_value);
                BNE: branch_taken = (rs1_value != rs2_value);
                BLT: branch_taken = ($signed(rs1_value) < $signed(rs2_value));
                BGE: branch_taken = ($signed(rs1_value) >= $signed(rs2_value));
                BLTU: branch_taken = (rs1_value < rs2_value);
                BGEU: branch_taken = (rs1_value >= rs2_value);
                default: branch_taken = 0;
                // Add other B-Type instructions here
            endcase
            // For B-Type instructions, calculate branch target
            branch_target = program_counter + (REGISTER_WIDTH'(decoded_instruction.instr.b_type.immediate) << 1);
        end
        OPCODE_JALR: begin // I-TYPE
            branch_taken = 1;
            branch_target = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
        end
        OPCODE_JAL: begin
            branch_taken = 1;
            branch_target = program_counter + (REGISTER_WIDTH'(decoded_instruction.instr.j_type.immediate) << 1);
        end
        default: begin 
        end
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