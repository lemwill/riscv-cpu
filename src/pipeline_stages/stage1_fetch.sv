module stage1_fetch #(
    parameter WIDTH = 32,
    DEPTH = 1024
) (
    input logic clk,
    input logic rst,
    MemoryInterface.read_out sramport_instruction_read,
    Axis.out axis_fetch_to_decode,
    input logic [WIDTH-1:0] branch_target,
    input logic branch_taken
);

  logic [WIDTH-1:0] program_counter;
  logic [WIDTH-1:0] program_counter_next;

  // Combinatorial calculation of next program counter
  always_comb begin
    if (rst) begin
      program_counter_next = 0;
    end else begin
      if (branch_taken) begin
        program_counter_next = branch_target;
      end else begin
        program_counter_next = program_counter + 4;
      end
    end
  end

  // Flops
  always_ff @(posedge clk) begin
    if (rst) begin
      program_counter <= -4;
    end else begin
      program_counter <= program_counter_next;
    end
  end


  // SRAM instruction read
  assign sramport_instruction_read.enable = 1;
  assign sramport_instruction_read.address = program_counter_next;
  assign axis_fetch_to_decode.tdata.instruction = sramport_instruction_read.data;
  assign axis_fetch_to_decode.tdata.program_counter = program_counter;



endmodule
