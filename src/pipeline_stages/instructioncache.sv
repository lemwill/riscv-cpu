module instructioncache #(
    parameter DATA_WIDTH=0,
    parameter DEPTH = 16
) (
    input logic clk,
    // MemoryInterface.write_in write,
    MemoryInterface.read_in read
);                                
  logic [DATA_WIDTH/4-1:0] memory[DEPTH-1:0];


    initial begin
        integer file = $fopen("../../../verification/software/program.hex", "r");
        integer value;
        integer i = 0;
        string line;
        integer ret;
        logic [7:0] byte_value [0:3];


        $display("Loading program.hex");
        
        $display("Looping");
        while (!$feof(file)) begin
            ret = $fscanf(file, "%h", value);
            if (ret == 0) continue; // skip empty lines
            if (ret != 1) begin
                $display("Failed to read line %0d of program.hex", i);
                $finish;
            end
            // Break the value into bytes
            for (int j = 0; j < 4; j++) begin
                memory[i+j] = value[(3-j)*8+:8];
            end
            // Reassemble the value in little-endian order
            i = i + 4;
        end

        $fclose(file);
    end

  // // Write Logic
  // always_ff @(posedge clk) begin
  //   if (write.enable == 1) begin
  //     memory[write.address] <= write.data;  // Write data to memory
  //   end
  // end

  // Read Logic
  always_ff @(posedge clk) begin
    if (read.enable == 1) begin
      read.data <= {memory[read.address+3], memory[read.address+2], memory[read.address+1], memory[read.address]};
    end
  end
endmodule
