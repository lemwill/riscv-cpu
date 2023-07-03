module instruction_fetch #(parameter WIDTH=32, DEPTH=1024)
(
    input logic clk, 
    input logic rst,
    output logic [WIDTH-1:0] instruction,
    output logic [WIDTH-1:0] program_counter
);

logic [WIDTH-1:0] current_program_counter;
logic [WIDTH-1:0] next_program_counter;

assign next_program_counter = current_program_counter + 4; 

always_ff @(posedge clk) 
begin
    if (rst) begin
        current_program_counter <= 0;
    end else begin
        current_program_counter <= next_program_counter;
    end
end

memory #(8, DEPTH) instruction_memory(
    .clk(clk),
    .rst(rst),
    .write_data(0),
    .write_en(0),
    .address(current_program_counter),
    .read_data(instruction)
);


endmodule