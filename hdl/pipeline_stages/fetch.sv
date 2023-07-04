module fetch #(parameter WIDTH=32, DEPTH=1024)
(
    input logic clk, 
    input logic rst,
    output logic [WIDTH-1:0] program_counter,
    input logic [WIDTH-1:0] branch_target,
    input logic branch_taken
);

always_ff @(posedge clk) 
begin
    if (rst) begin
        program_counter <= 0;
    end else begin
        if (branch_taken) begin
            program_counter <= branch_target;
        end else begin
            program_counter <= program_counter + 4;
        end
    end
end


endmodule