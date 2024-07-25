module stage4_memory (
    input logic clk,
    input logic rst,
    Axis.in axis_execute_to_memory,
    Axis.out axis_memory_to_writeback,
    MemoryInterfaceSinglePort.master sramport_data
);
  instruction_t decoded_instruction;
  RegisterValue rs1_value;
  RegisterValue rs2_value;

  assign decoded_instruction = axis_execute_to_memory.tdata.decoded_instruction;
  assign rs1_value = axis_execute_to_memory.tdata.rs1_value;
  assign rs2_value = axis_execute_to_memory.tdata.rs2_value;

  always_comb begin
    sramport_data.write_data   = 0;
    sramport_data.write_enable = 0;
    sramport_data.enable       = 0;
    sramport_data.address      = 0;
    sramport_data.byte_enable  = '1;

    if (decoded_instruction.opcode == OP_LOAD) begin
      sramport_data.address = rs1_value +
          REGISTER_WIDTH'($signed(decoded_instruction.instr.i_type.immediate));
      sramport_data.enable = 1;
      case (decoded_instruction.instr.i_type.funct3)
        LB: sramport_data.byte_enable = 4'b1;
        LH: sramport_data.byte_enable = 4'b11;
        LBU: sramport_data.byte_enable = 4'b1;
        LHU: sramport_data.byte_enable = 4'b11;
        default: sramport_data.byte_enable = '1;
      endcase
    end else if (decoded_instruction.opcode == OP_STORE) begin
      sramport_data.address = rs1_value +
          REGISTER_WIDTH'($signed(decoded_instruction.instr.s_type.immediate));
      sramport_data.write_data = rs2_value;
      sramport_data.write_enable = 1;
      sramport_data.enable = 1;
      case (decoded_instruction.instr.s_type.funct3)
        SB: sramport_data.byte_enable = 4'b1;
        SH: sramport_data.byte_enable = 4'b11;
        default: sramport_data.byte_enable = '1;
      endcase
    end
  end

  assign axis_execute_to_memory.tready = axis_memory_to_writeback.tready;

  always_ff @(posedge clk) begin
    if (rst) begin
    end else begin
      axis_memory_to_writeback.tvalid <= 0;
      if (axis_execute_to_memory.tvalid) begin
        axis_memory_to_writeback.tvalid <= 1;
        axis_memory_to_writeback.tdata.data_from_memory <= sramport_data.read_data;
        axis_memory_to_writeback.tdata.branch_target <= axis_execute_to_memory.tdata.branch_target;
        axis_memory_to_writeback.tdata.alu_result <= axis_execute_to_memory.tdata.alu_result;
        axis_memory_to_writeback.tdata.decoded_instruction <= decoded_instruction;
      end
    end
  end

endmodule
