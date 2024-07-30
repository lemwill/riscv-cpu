module pipeline_logger #(
    parameter integer NUM_COLORS = 8
) (
    input logic clk,
    input logic rst,
    Axis.monitor axis_fetch_to_decode,
    Axis.monitor axis_decode_to_execute,
    Axis.monitor axis_execute_to_memory,
    Axis.monitor axis_memory_to_writeback,
    MemoryInterfaceSinglePort.master sramport_data
);

  typedef enum logic [2:0] {
    COLOR_RED     = 3'b000,
    COLOR_GREEN   = 3'b001,
    COLOR_BLUE    = 3'b010,
    COLOR_YELLOW  = 3'b011,
    COLOR_MAGENTA = 3'b100,
    COLOR_CYAN    = 3'b101,
    COLOR_WHITE   = 3'b110,
    COLOR_BLACK   = 3'b111
  } color_t;

  color_t instruction_colors[0:NUM_COLORS-1];

  integer log_file;
  string fetch_buffer = "";
  string decode_buffer = "";
  string execute_buffer = "";
  string memory_buffer = "";
  string writeback_buffer = "";

  localparam int FETCH_WIDTH = 15;
  localparam int DECODE_WIDTH = 40;
  localparam int EXECUTE_WIDTH = 40;
  localparam int MEMORY_WIDTH = 40;
  localparam int WRITEBACK_WIDTH = 40;

  initial begin
    instruction_colors[0] = COLOR_RED;
    instruction_colors[1] = COLOR_GREEN;
    instruction_colors[2] = COLOR_BLUE;
    instruction_colors[3] = COLOR_YELLOW;
    instruction_colors[4] = COLOR_MAGENTA;
    instruction_colors[5] = COLOR_CYAN;
    instruction_colors[6] = COLOR_WHITE;
    instruction_colors[7] = COLOR_BLACK;

    log_file = $fopen("pipeline_log.txt", "w");
    if (log_file == 0) begin
      $fatal("Failed to open log file.");
    end
    // Print column headers
    $fwrite(log_file, "%-6s %-15s %-40s %-40s %-40s %-40s\n", "Cycle", "FETCH", "DECODE",
            "EXECUTE", "MEMORY", "WRITEBACK");
  end

  // Reusing existing functions and variables

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // Reset logic
      cycle_count = 0;
      fetch_buffer = "";
      decode_buffer = "";
      execute_buffer = "";
      memory_buffer = "";
      writeback_buffer = "";
      $fclose(log_file);
      log_file = $fopen("pipeline_log.txt", "w");
      if (log_file == 0) begin
        $fatal("Failed to open log file.");
      end
      // Print column headers
      $fwrite(log_file, "%-6s %-15s %-40s %-40s %-40s %-40s\n", "Cycle", "FETCH", "DECODE",
              "EXECUTE", "MEMORY", "WRITEBACK");
    end else begin
      cycle_count++;

      // Fetch stage
      if (axis_fetch_to_decode.tvalid && axis_fetch_to_decode.tready) begin
        fetch_buffer = $sformatf("PC:%h", axis_fetch_to_decode.tdata.program_counter);
      end else begin
        fetch_buffer = "...";
      end

      // Decode stage
      if (axis_decode_to_execute.tvalid && axis_decode_to_execute.tready) begin
        decode_buffer = $sformatf(
            "OPCODE:%0d, %s",
            axis_decode_to_execute.tdata.decoded_instruction.opcode,
            get_instruction_description(
              axis_decode_to_execute.tdata.decoded_instruction
            )
        );
      end else begin
        decode_buffer = "...";
      end

      // Execute stage
      if (axis_execute_to_memory.tvalid && axis_execute_to_memory.tready) begin
        execute_buffer = $sformatf(
            "OPCODE:%0d, Res:%h",
            axis_execute_to_memory.tdata.decoded_instruction.opcode,
            axis_execute_to_memory.tdata.alu_result
        );
      end else begin
        execute_buffer = "...";
      end

      // Memory stage
      if (axis_memory_to_writeback.tvalid && axis_memory_to_writeback.tready) begin
        memory_buffer = $sformatf(
            "OPCODE:%0d, Addr:%0h, R/W Data:%0d",
            axis_memory_to_writeback.tdata.decoded_instruction.opcode,
            sramport_data.address,
            axis_memory_to_writeback.tdata.decoded_instruction.opcode == common::OP_STORE ? sramport_data.write_data : sramport_data.read_data
        );
      end else begin
        memory_buffer = "...";
      end

      // Writeback stage
      if (axis_memory_to_writeback.tvalid && axis_memory_to_writeback.tready) begin
        writeback_buffer = $sformatf(
            "OPCODE:%0d, Reg:%0d, Data:%h",
            axis_memory_to_writeback.tdata.decoded_instruction.opcode,
            axis_memory_to_writeback.tdata.decoded_instruction.rd,
            axis_memory_to_writeback.tdata.alu_result
        );
      end else begin
        writeback_buffer = "...";
      end

      // Write the buffers to the file with fixed column widths
      $fwrite(log_file, "%-6d %-15s %-40s %-40s %-40s %-40s\n", cycle_count, fetch_buffer,
              decode_buffer, execute_buffer, memory_buffer, writeback_buffer);
    end
  end

  final begin
    $fclose(log_file);
  end
endmodule
