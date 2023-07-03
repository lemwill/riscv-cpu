module arithmetic_logic_unit
    (
        input logic [REGISTER_WIDTH-1:0] input1,
        input logic [REGISTER_WIDTH-1:0] input2,
        input instruction_t decoded_instruction,
        output logic [REGISTER_WIDTH-1:0] result
    );
    
        always_comb
        begin 
            case (decoded_instruction.funct3)
                ADDI: result = input1 + input2;
                default: result = 0;
            endcase
        end
    
    endmodule
    