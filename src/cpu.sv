
// Define inputs and outputs
import common::*;

module cpu (
    input logic clk,
    input logic rst
);



logic [REGISTER_WIDTH-1:0] instruction;
OpCode opcode;
logic [REGISTER_WIDTH-1:0] program_counter;
logic [REGISTER_WIDTH-1:0] alu_result;
logic [REGISTER_WIDTH-1:0] rs1_value;
logic [REGISTER_WIDTH-1:0] rs2_value;
logic [REGISTER_WIDTH-1:0] write_data;
logic [$clog2(REGISTER_DEPTH)-1:0] write_address;
logic write_enable;
logic read_enable;
logic [$clog2(REGISTER_DEPTH)-1:0] read_address_1;
logic [$clog2(REGISTER_DEPTH)-1:0] read_address_2;


// Instanciate the instruction fetch
instruction_fetch instruction_fetch_inst (
    .clk(clk),
    .rst(rst),
    .instruction(instruction),
    .program_counter(program_counter)
);

instruction_t decoded_instruction;

// Instanciate the instruction decode
instruction_decode instruction_decode_inst (
    .instruction(instruction),
    .decoded_instruction(decoded_instruction)
);

// Instanciate execute stage
execution_unit execution_unit_inst (
    .clk(clk),
    .rs1_value(rs1_value),
    .rs2_value(rs2_value),
    .decoded_instruction(decoded_instruction),
    .alu_result(alu_result)
);

always_comb begin
    write_data = 0;
    write_address = 0;
    write_enable = 0;
    read_address_1 = 0;
    read_address_2 = 0;
    read_enable = 0;
    if (decoded_instruction.opcode == I_TYPE) begin
        // For ALU operations, the result comes from the ALU, and the destination is rd
        write_enable = 1'b1;
        write_data = alu_result;
        write_address = decoded_instruction.instr.i_type.rd;
        read_address_1 = decoded_instruction.instr.i_type.rs1;
        read_enable = 1;
    end
end

  

// Instantiate the register file
register_file register_file_inst (
    .clk(clk),
    .rst(rst),
    .read_enable(read_enable),
    .read_address_1(read_address_1),
    .read_address_2(read_address_2),
    .write_enable(write_enable),
    .write_address(write_address),
    .write_data(write_data),
    .read_data_1(rs1_value),
    .read_data_2(rs2_value)
);

endmodule

