
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
logic [REGISTER_WIDTH-1:0] branch_target;
logic [$clog2(REGISTER_DEPTH)-1:0] write_address;
logic write_enable;
logic read_enable;
logic [$clog2(REGISTER_DEPTH)-1:0] read_address_1;
logic [$clog2(REGISTER_DEPTH)-1:0] read_address_2;
logic branch_taken;
logic [REGISTER_WIDTH-1:0] port1_address;
logic [REGISTER_WIDTH-1:0] port1_write_data;
logic port1_write_en;
logic [REGISTER_WIDTH/BYTE_WIDTH-1:0] port1_byte_enable;

// Instanciate the instruction fetch
fetch fetch_inst (
    .clk(clk),
    .rst(rst),
    .branch_target(branch_target),
    .program_counter(program_counter),
    .branch_taken(branch_taken)
);

logic [REGISTER_WIDTH-1:0] port1_read_data;
 
// Memory read and write mux
always_comb begin
    
    port1_write_data  = 0;
    port1_write_en    = 0;
    port1_address     = 0;
    port1_byte_enable = '1;

    if (decoded_instruction.opcode == OPCODE_LOAD) begin 
        port1_address = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
        case (decoded_instruction.instr.i_type.funct3)
            LB: port1_byte_enable = 4'b1;
            LH: port1_byte_enable = 4'b11;
            LBU: port1_byte_enable = 4'b1;
            LHU: port1_byte_enable = 4'b11;
            default: port1_byte_enable = '1;
        endcase
    end else if (decoded_instruction.opcode == OPCODE_STORE) begin 
        port1_address = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.s_type.immediate);      
        port1_write_data = rs2_value;
        port1_write_en = 1;
        case (decoded_instruction.instr.s_type.funct3)
            SB: port1_byte_enable = 4'b1;
            SH: port1_byte_enable = 4'b11;
            default: port1_byte_enable = '1;
        endcase
    end
end 

memory #(8, 1000) instruction_memory(
    .clk(clk),
    .rst(rst),
    .port1_write_data(port1_write_data),
    .port1_write_en(port1_write_en),
    .port1_address(port1_address),
    .port1_byte_enable(port1_byte_enable),
    .port1_read_data(port1_read_data),
    .port2_address(program_counter),
    .port2_read_data(instruction)
);

instruction_t decoded_instruction;

// Instanciate the instruction decode
decode decode_inst (
    .instruction(instruction),
    .decoded_instruction(decoded_instruction)
);

// Instanciate execute stage
execute execute_inst (
    .clk(clk),
    .rs1_value(rs1_value),
    .rs2_value(rs2_value),
    .decoded_instruction(decoded_instruction),
    .alu_result(alu_result),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .program_counter(program_counter)
);

// Register Write and Read Mux
always_comb begin
    write_data     = 0;
    write_address  = 0;
    write_enable   = 0;
    read_address_1 = 0;
    read_address_2 = 0;
    read_enable    = 0;

    if (decoded_instruction.opcode == OPCODE_ARITHMETIC_IMMEDIATE || 
        decoded_instruction.opcode == OPCODE_JALR ||
        decoded_instruction.opcode == OPCODE_ARITHMETIC) begin
        // For ALU operations, the result comes from the ALU, and the destination is rd
        write_enable = 1'b1;
        write_data = alu_result;
        write_address = decoded_instruction.instr.i_type.rd;
        read_address_1 = decoded_instruction.instr.i_type.rs1;
        read_enable = 1;
    end else if (decoded_instruction.opcode == OPCODE_JAL) begin 
        // For JAL, the result comes from the ALU, and the destination is rd
        write_enable = 1'b1;
        write_data = branch_target;
        write_address = decoded_instruction.instr.j_type.rd;
    end else if (decoded_instruction.opcode == OPCODE_STORE) begin 
        // For store, the result comes from rs2, and the destination is rs1
        read_address_1 = decoded_instruction.instr.s_type.rs1;
        read_address_2 = decoded_instruction.instr.s_type.rs2;
        read_enable = 1;
    end else if (decoded_instruction.opcode == OPCODE_LOAD) begin
        write_address = decoded_instruction.instr.i_type.rd;
        write_enable = 1'b1;
        case (decoded_instruction.instr.i_type.funct3)
            LB: write_data = {{(REGISTER_WIDTH-BYTE_WIDTH){port1_read_data[BYTE_WIDTH-1]}}, port1_read_data[BYTE_WIDTH-1:0]};
            LH: write_data = {{(REGISTER_WIDTH-2*BYTE_WIDTH){port1_read_data[2*BYTE_WIDTH-1]}}, port1_read_data[2*BYTE_WIDTH-1:0]};
            LBU: write_data = { {REGISTER_WIDTH-BYTE_WIDTH{1'b0}}, port1_read_data[BYTE_WIDTH-1:0] };
            LHU: write_data = { {REGISTER_WIDTH-2*BYTE_WIDTH{1'b0}}, port1_read_data[2*BYTE_WIDTH-1:0] };
            default: write_data = port1_read_data;
        endcase
    end else if (decoded_instruction.opcode == OPCODE_BRANCH) begin
        read_address_1 = decoded_instruction.instr.b_type.rs1;
        read_address_2 = decoded_instruction.instr.b_type.rs2;
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

