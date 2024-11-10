module stage5_writeback (
    input clk,
    input rst,
    Axis.in axis_memory_to_writeback,
    MemoryInterface.write_out registerport_write,
    MemoryInterfaceSinglePort.master sramport_data
);

  logic [REGISTER_WIDTH-1:0] write_data;
  logic [$clog2(REGISTER_DEPTH)-1:0] write_address;
  logic write_enable;

  // Task to handle arithmetic and JALR instructions
  task handle_arithmetic_jalr();
    write_enable = 1'b1;
    write_data = axis_memory_to_writeback.tdata.alu_result;
    write_address = axis_memory_to_writeback.tdata.decoded_instruction.rd;
  endtask

  // Task to handle JAL instruction
  task handle_jal();
    write_enable = 1'b1;
    write_data = axis_memory_to_writeback.tdata.branch_target;
    write_address = axis_memory_to_writeback.tdata.decoded_instruction.rd;
  endtask

  // Task to handle LOAD instruction
  task handle_load();
    write_address = axis_memory_to_writeback.tdata.decoded_instruction.rd;
    write_enable  = 1'b1;
    case (axis_memory_to_writeback.tdata.decoded_instruction.funct3)
      LB:
      write_data = {
        {(REGISTER_WIDTH - BYTE_WIDTH) {sramport_data.read_data[BYTE_WIDTH-1]}},
        sramport_data.read_data[BYTE_WIDTH-1:0]
      };
      LH:
      write_data = {
        {(REGISTER_WIDTH - 2 * BYTE_WIDTH) {sramport_data.read_data[2*BYTE_WIDTH-1]}},
        sramport_data.read_data[2*BYTE_WIDTH-1:0]
      };
      LBU:
      write_data = {{REGISTER_WIDTH - BYTE_WIDTH{1'b0}}, sramport_data.read_data[BYTE_WIDTH-1:0]};
      LHU:
      write_data = {
        {REGISTER_WIDTH - 2 * BYTE_WIDTH{1'b0}}, sramport_data.read_data[2*BYTE_WIDTH-1:0]
      };
      default: write_data = sramport_data.read_data;
    endcase
  endtask

  always begin
    write_data = 0;
    write_address = 0;
    write_enable = 0;

    if (axis_memory_to_writeback.tvalid) begin
      case (axis_memory_to_writeback.tdata.decoded_instruction.opcode)
        OP_ARITHMETIC_IMMEDIATE, OP_JALR, OP_ARITHMETIC: handle_arithmetic_jalr();
        OP_JAL: handle_jal();
        OP_LOAD: handle_load();
        default: begin
          write_enable = 0;
          write_data = 0;
          write_address = 0;
        end
      endcase
    end
  end

  assign axis_memory_to_writeback.tready = 1'b1;
  assign registerport_write.data = write_data;
  assign registerport_write.address = write_address;
  assign registerport_write.enable = write_enable;

endmodule
