module write_back #(parameter WIDTH=32)
    (
        input wire clk,
        input wire [WIDTH-1:0] alu_result,
        input wire [4:0] rd,
        output wire [WIDTH-1:0] write_data
    );
    
        // For simplicity, we directly route ALU result to write_data output.
        assign write_data = alu_result;
    
    endmodule
    