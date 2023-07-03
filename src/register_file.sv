import common::*;

module register_file (
    input logic clk,
    input logic rst,
    input logic read_enable, 
    input logic [$clog2(REGISTER_DEPTH)-1:0] read_address_1,
    input logic [$clog2(REGISTER_DEPTH)-1:0] read_address_2,
    input logic write_enable,
    input logic [$clog2(REGISTER_DEPTH)-1:0] write_address,
    input logic [REGISTER_WIDTH-1:0] write_data,
    output logic [REGISTER_WIDTH-1:0] read_data_1,
    output logic [REGISTER_WIDTH-1:0] read_data_2
);

logic [REGISTER_WIDTH-1:0] registers [REGISTER_DEPTH-1:0];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i=0; i<REGISTER_DEPTH; i++) begin
            registers[i] <= 0;
        end
    end else begin
        if (write_enable) begin
            registers[write_address] <= write_data;
        end
    end
end

always @* begin
    if (read_enable) begin
        read_data_1 = registers[read_address_1];
        read_data_2 = registers[read_address_2];
    end else begin
        read_data_1 = 0;
        read_data_2 = 0;
    end
end


endmodule