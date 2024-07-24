
// Define inputs and outputs
import common::*;

module cpu (
    input logic clk,
    input logic rst
);

  Axis #(fetch_to_decode_t) axis_fetch_to_decode ();
  Axis #(decode_to_execute_t) axis_decode_to_execute ();
  Axis #(execute_to_memory_t) axis_execute_to_memory ();
  Axis #(memory_to_writeback_t) axis_memory_to_writeback ();

  MemoryInterfaceSinglePort #(logic [31:0], 32) sramport_data ();
  MemoryInterface #(logic [31:0], 32) sramport_instruction_read ();
  MemoryInterface #(logic [31:0], $clog2(REGISTER_DEPTH)) registerport_write ();
  MemoryInterface #(logic [31:0], $clog2(REGISTER_DEPTH)) registerport_read_1 ();
  MemoryInterface #(logic [31:0], $clog2(REGISTER_DEPTH)) registerport_read_2 ();

  logic [31:0] branch_target;
  logic branch_taken;
  logic drop_instruction_decode_stage;


  instructioncache #(
      .DEPTH(10000),
      .DATA_WIDTH(REGISTER_WIDTH)
  ) i_instructioncache (
      .clk,
      .read(sramport_instruction_read)
  );

  datacache #(
      .DATA_WIDTH(REGISTER_WIDTH),
      .DEPTH(10000)
  ) i_datacache (
      .clk,
      .read_write(sramport_data)
  );

  // Instantiate the register file
  registers i_registers (
      .clk,
      .rst,
      .registerport_write,
      .registerport_read_1,
      .registerport_read_2
  );

  stage1_fetch i_stage1_fetch (
      .clk,
      .rst,
      .sramport_instruction_read,
      .axis_fetch_to_decode,
      .branch_target,
      .branch_taken
  );

  stage2_decode i_stage2_decode (
      .clk,
      .rst,
      .drop_instruction_decode_stage,
      .axis_fetch_to_decode,
      .axis_decode_to_execute,
      .registerport_read_1,
      .registerport_read_2
  );

  stage3_execute i_stage3_execute (
      .clk,
      .rst,
      .drop_instruction_decode_stage,
      .axis_decode_to_execute,
      .axis_execute_to_memory,
      .branch_target,
      .branch_taken
  );

  stage4_memory i_stage4_memory (
      .clk,
      .rst,
      .axis_execute_to_memory,
      .axis_memory_to_writeback,
      .sramport_data
  );

  stage5_writeback i_stage5_writeback (
      .clk,
      .rst,
      .axis_memory_to_writeback,
      .registerport_write
  );

endmodule

