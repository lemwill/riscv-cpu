module memory #(parameter WIDTH=8, DEPTH)
    (
        input logic clk,
        input logic rst, 
        input logic                       port1_write_en,
        input logic [REGISTER_WIDTH-1:0]  port1_write_data,
        input logic [REGISTER_WIDTH-1:0]  port1_address,
        output logic [REGISTER_WIDTH-1:0] port1_read_data,
        input logic [REGISTER_WIDTH-1:0]  port2_address,
        output logic [REGISTER_WIDTH-1:0] port2_read_data
    );
    
        logic [WIDTH-1:0] mem [DEPTH-1:0];
    
        initial begin
            integer file = $fopen("../verification/software/program.hex", "r");
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
                    mem[i+j] = value[j*8+:8];
                end
                // Reassemble the value in little-endian order
                i = i + 4;
            end
        
            $fclose(file);
        end
    
        always_ff @(posedge clk) begin
            if (rst) begin
                for (int i=0; i<DEPTH; i++) begin
                    mem[i] = 0;
                end
            end else if (port1_write_en) begin
                for (int i = 0; i < 4; i = i + 1) begin
                    mem[port1_address+i] <= port1_write_data[8*i +: 8];// Verify bit order
                end
            end
        end
        
        always_comb begin
            port1_read_data = {mem[port1_address], mem[port1_address+1], mem[port1_address+2], mem[port1_address+3]};
        end

        always_comb begin
            port2_read_data = {mem[port2_address], mem[port2_address+1], mem[port2_address+2], mem[port2_address+3]};
        end
    endmodule
    
