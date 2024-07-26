module forwarding_unit (
    Axis.in axis_decode_to_execute,
    Axis.in axis_execute_to_memory,
    Axis.in axis_memory_to_writeback,
    output RegisterValue rs1_value,
    output RegisterValue rs2_value
);

  always_comb begin
    // Default values
    rs1_value = axis_decode_to_execute.tdata.rs1_value;
    rs2_value = axis_decode_to_execute.tdata.rs2_value;

    // Forwarding from execute stage
    if (axis_execute_to_memory.tvalid && axis_execute_to_memory.tdata.decoded_instruction.opcode != 0) begin
      if (axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC_IMMEDIATE ||
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_LOAD || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_STORE || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_BRANCH || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_JALR) begin
        if (axis_decode_to_execute.tdata.decoded_instruction.rs1 == axis_execute_to_memory.tdata.decoded_instruction.rd) begin
          rs1_value = axis_execute_to_memory.tdata.alu_result;
        end
      end

      if (axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC ||
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_STORE || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_BRANCH) begin
        if (axis_decode_to_execute.tdata.decoded_instruction.rs2 == axis_execute_to_memory.tdata.decoded_instruction.rd) begin
          rs2_value = axis_execute_to_memory.tdata.alu_result;
        end
      end
    end

    // Forwarding from memory stage
    if (axis_memory_to_writeback.tvalid && axis_memory_to_writeback.tdata.decoded_instruction.opcode != 0) begin
      if (axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC_IMMEDIATE ||
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_LOAD || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_STORE || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_BRANCH || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_JALR) begin
        if (axis_decode_to_execute.tdata.decoded_instruction.rs1 == axis_memory_to_writeback.tdata.decoded_instruction.rd) begin
          rs1_value = axis_memory_to_writeback.tdata.alu_result;
        end
      end

      if (axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_ARITHMETIC ||
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_STORE || 
          axis_decode_to_execute.tdata.decoded_instruction.opcode == OP_BRANCH) begin
        if (axis_decode_to_execute.tdata.decoded_instruction.rs2 == axis_memory_to_writeback.tdata.decoded_instruction.rd) begin
          rs2_value = axis_memory_to_writeback.tdata.alu_result;
        end
      end
    end
  end

endmodule
