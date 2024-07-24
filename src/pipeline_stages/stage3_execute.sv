import common::*;

module stage3_execute (
    input logic clk,
    input logic rst,
    output logic branch_taken,
    output logic [REGISTER_WIDTH-1:0] branch_target,
    output logic drop_instruction_decode_stage,
    Axis.in axis_decode_to_execute,
    Axis.out axis_execute_to_memory
);

  //====================================================================================
  // Signal definitions
  //====================================================================================
  logic [REGISTER_WIDTH-1:0] alu_input2;
  logic [REGISTER_WIDTH-1:0] immediate;
  logic [REGISTER_WIDTH-1:0] alu_result;
  logic [REGISTER_WIDTH-1:0] program_counter;
  instruction_t decoded_instruction;
  RegisterValue rs1_value;
  RegisterValue rs2_value;

  logic [REGISTER_WIDTH-1:0] load_address;
  logic [REGISTER_WIDTH-1:0] store_address;
  logic [REGISTER_WIDTH-1:0] store_data;
  logic branch_taken_next;
  logic [REGISTER_WIDTH-1:0] branch_target_next;
  logic drop_instruction_execute_stage;


  //====================================================================================
  // Combinatorial assignements
  //====================================================================================
  assign decoded_instruction = axis_decode_to_execute.tdata.decoded_instruction;
  assign program_counter = axis_decode_to_execute.tdata.program_counter;
  assign rs1_value = axis_decode_to_execute.tdata.rs1_value;
  assign rs2_value = axis_decode_to_execute.tdata.rs2_value;

  //====================================================================================
  // Opcode tasks
  //====================================================================================
  task handle_arithmetic_immediate();
    alu_input2 = REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
    case (decoded_instruction.instr.i_type.funct3)
      ADDI_OR_JAL: alu_result = rs1_value + alu_input2;
      XORI: alu_result = rs1_value ^ alu_input2;
      ORI: alu_result = rs1_value | alu_input2;
      ANDI: alu_result = rs1_value & alu_input2;
      SLLI: alu_result = rs1_value << alu_input2[4:0];
      SRLI_OR_SRAI: alu_result = rs1_value >> alu_input2[4:0];
      SLTI: alu_result = (rs1_value < alu_input2) ? 1 : 0;
      SLTUI: alu_result = (rs1_value < alu_input2) ? 1 : 0;
      default: alu_result = 0;
    endcase
  endtask

  task handle_arithmetic();
    alu_input2 = rs2_value;
    case (decoded_instruction.instr.i_type.funct3)
      ADD_OR_SUB: alu_result = rs1_value + alu_input2;
      XOR: alu_result = rs1_value ^ alu_input2;
      OR: alu_result = rs1_value | alu_input2;
      AND: alu_result = rs1_value & alu_input2;
      SLL: alu_result = rs1_value << alu_input2[4:0];
      SRL_OR_SRA: alu_result = rs1_value >> alu_input2[4:0];
      SLT: alu_result = (rs1_value < alu_input2) ? 1 : 0;
      SLTU: alu_result = (rs1_value < alu_input2) ? 1 : 0;
      default: alu_result = 0;
    endcase
  endtask

  task handle_branch();
    case (decoded_instruction.instr.b_type.funct3)
      BEQ: branch_taken_next = (rs1_value == rs2_value);
      BNE: branch_taken_next = (rs1_value != rs2_value);
      BLT: branch_taken_next = ($signed(rs1_value) < $signed(rs2_value));
      BGE: branch_taken_next = ($signed(rs1_value) >= $signed(rs2_value));
      BLTU: branch_taken_next = (rs1_value < rs2_value);
      BGEU: branch_taken_next = (rs1_value >= rs2_value);
      default: branch_taken_next = 0;
    endcase
    branch_target_next = program_counter + (REGISTER_WIDTH'(decoded_instruction.instr.b_type.immediate) << 1);
  endtask

  task handle_jalr();
    branch_taken_next  = 1;
    branch_target_next = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
  endtask

  task handle_jal();
    branch_taken_next = 1;
    branch_target_next = program_counter +
        (REGISTER_WIDTH'($signed(decoded_instruction.instr.j_type.immediate)) << 1);
  endtask

  task handle_load();
    load_address = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
  endtask

  task handle_store();
    store_address = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.s_type.immediate);
    store_data = rs2_value;
  endtask

  //====================================================================================
  // Handle opcode process
  //====================================================================================
  always begin
    branch_taken_next = 0;
    alu_input2 = 0;
    branch_target_next = 0;
    load_address = 0;
    store_address = 0;
    store_data = 0;
    alu_result = 0;
    case (decoded_instruction.opcode)
      OP_ARITHMETIC_IMMEDIATE: handle_arithmetic_immediate();
      OP_ARITHMETIC: handle_arithmetic();
      OP_BRANCH: handle_branch();
      OP_JALR: handle_jalr();
      OP_JAL: handle_jal();
      OP_LOAD: handle_load();
      OP_STORE: handle_store();
      default: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      axis_execute_to_memory.tvalid <= 0;
      branch_taken <= 0;
      axis_execute_to_memory.tdata.branch_taken <= 0;
      drop_instruction_decode_stage <= 0;
      drop_instruction_execute_stage <= 0;
    end else begin
      axis_execute_to_memory.tvalid <= 0;
      branch_taken <= 0;
      axis_execute_to_memory.tdata.branch_taken <= 0;
      drop_instruction_decode_stage <= 0;
      drop_instruction_execute_stage <= 0;

      if (axis_decode_to_execute.tvalid && !drop_instruction_execute_stage) begin
        axis_execute_to_memory.tvalid <= 1;
        axis_execute_to_memory.tdata.decoded_instruction <= decoded_instruction;
        axis_execute_to_memory.tdata.rs1_value <= rs1_value;
        axis_execute_to_memory.tdata.rs2_value <= rs2_value;
        axis_execute_to_memory.tdata.alu_result <= alu_result;
        axis_execute_to_memory.tdata.branch_taken <= branch_taken_next;
        axis_execute_to_memory.tdata.branch_target <= branch_target_next;

        if (axis_decode_to_execute.tdata.branch_taken_prediction != branch_taken_next) begin
          branch_taken <= branch_taken_next;
          branch_target <= branch_target_next;
          drop_instruction_decode_stage <= 1;
          drop_instruction_execute_stage <= 1;
        end

      end
    end
  end

  assign axis_decode_to_execute.tready = axis_execute_to_memory.tready;

endmodule
