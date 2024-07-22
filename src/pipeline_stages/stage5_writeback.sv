module stage5_writeback (
    input clk,
    input rst,
    Axis.in axis_memory_to_writeback,
    MemoryInterface.write_out registerport_write
);

  logic [REGISTER_WIDTH-1:0] write_data;
  logic [$clog2(REGISTER_DEPTH)-1:0] write_address;
  logic write_enable;

  always_comb begin
    write_data = 0;
    write_address = 0;
    write_enable = 0;

    if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == OPCODE_ARITHMETIC_IMMEDIATE || 
        axis_memory_to_writeback.tdata.decoded_instruction.opcode == OPCODE_JALR ||
        axis_memory_to_writeback.tdata.decoded_instruction.opcode == OPCODE_ARITHMETIC) begin
      write_enable = 1'b1;
      write_data = axis_memory_to_writeback.tdata.alu_result;
      write_address = axis_memory_to_writeback.tdata.decoded_instruction.instr.i_type.rd;
    end else if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == OPCODE_JAL) begin
      write_enable = 1'b1;
      write_data = axis_memory_to_writeback.tdata.branch_target;
      write_address = axis_memory_to_writeback.tdata.decoded_instruction.instr.j_type.rd;
    end else if (axis_memory_to_writeback.tdata.decoded_instruction.opcode == OPCODE_LOAD) begin
      write_address = axis_memory_to_writeback.tdata.decoded_instruction.instr.i_type.rd;
      write_enable  = 1'b1;
      case (axis_memory_to_writeback.tdata.decoded_instruction.instr.i_type.funct3)
        LB:
        write_data = {
          {(REGISTER_WIDTH - BYTE_WIDTH) {axis_memory_to_writeback.tdata.data_from_memory[BYTE_WIDTH-1]}},
          axis_memory_to_writeback.tdata.data_from_memory[BYTE_WIDTH-1:0]
        };
        LH:
        write_data = {
          {(REGISTER_WIDTH - 2 * BYTE_WIDTH) {axis_memory_to_writeback.tdata.data_from_memory[2*BYTE_WIDTH-1]}},
          axis_memory_to_writeback.tdata.data_from_memory[2*BYTE_WIDTH-1:0]
        };
        LBU:
        write_data = {
          {REGISTER_WIDTH - BYTE_WIDTH{1'b0}}, axis_memory_to_writeback.tdata.data_from_memory[BYTE_WIDTH-1:0]
        };
        LHU:
        write_data = {
          {REGISTER_WIDTH - 2 * BYTE_WIDTH{1'b0}}, axis_memory_to_writeback.tdata.data_from_memory[2*BYTE_WIDTH-1:0]
        };
        default: write_data = axis_memory_to_writeback.tdata.data_from_memory;
      endcase
    end
  end

  assign registerport_write.data = write_data;
  assign registerport_write.address = write_address;
  assign registerport_write.enable = write_enable;

endmodule