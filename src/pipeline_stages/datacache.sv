module datacache #(
    parameter DATA_WIDTH = 0,
    parameter DEPTH = 16
) (
    input logic clk,
    MemoryInterfaceSinglePort.slave read_write
);
  logic [DATA_WIDTH/4-1:0] memory[DEPTH*4-1:0];

  // Write Logic
  always_ff @(posedge clk) begin
    if (read_write.enable == 1) begin
      for (int i = 0; i < 4; i = i + 1) begin
        if (read_write.byte_enable[i]) begin
          memory[read_write.address+i] <= read_write.write_data[8*i+:8];  // Verify bit order
        end
      end
    end else begin
      read_write.read_data <= {
        memory[read_write.address+3], memory[read_write.address+2], memory[read_write.address+1], memory[read_write.address]
      };
    end
  end

endmodule
