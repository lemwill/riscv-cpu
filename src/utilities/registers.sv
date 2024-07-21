import common::*;

module registers (
    input logic clk,
    input logic rst,
    MemoryInterface.write_in registerport_write,
    MemoryInterface.read_in registerport_read_1,
    MemoryInterface.read_in registerport_read_2
);

logic [REGISTER_WIDTH-1:0] registers [REGISTER_DEPTH-1:0];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i=0; i<REGISTER_DEPTH; i++) begin
            registers[i] <= 0;
        end
    end else begin
        if (registerport_write.enable && registerport_write.address != 0) begin
            // Ignore any write attempts to x0
            registers[registerport_write.address] <= registerport_write.data;
        end
    end
end

always_comb begin
    if (registerport_read_1.address == 0) begin
        registerport_read_1.data = 0;
    end else begin
        registerport_read_1.data = registers[registerport_read_1.address];
    end

    if (registerport_read_2.address == 0) begin
        registerport_read_2.data = 0;
    end else begin
        registerport_read_2.data = registers[registerport_read_2.address];
    end
end


endmodule