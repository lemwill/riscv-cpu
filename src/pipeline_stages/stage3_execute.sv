import common::*;

module stage3_execute (
    input logic clk,
    input logic rst,
    output logic branch_taken,
    output logic [REGISTER_WIDTH-1:0] branch_target,
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
  endtask

  task handle_arithmetic();
    alu_input2 = rs2_value;
  endtask

  task handle_branch();
    case (decoded_instruction.instr.b_type.funct3)
      BEQ: branch_taken = (rs1_value == rs2_value);
      BNE: branch_taken = (rs1_value != rs2_value);
      BLT: branch_taken = ($signed(rs1_value) < $signed(rs2_value));
      BGE: branch_taken = ($signed(rs1_value) >= $signed(rs2_value));
      BLTU: branch_taken = (rs1_value < rs2_value);
      BGEU: branch_taken = (rs1_value >= rs2_value);
      default: branch_taken = 0;
    endcase
    branch_target = program_counter + (REGISTER_WIDTH'(decoded_instruction.instr.b_type.immediate) << 1);
  endtask

  task handle_jalr();
    branch_taken  = 1;
    branch_target = rs1_value + REGISTER_WIDTH'(decoded_instruction.instr.i_type.immediate);
  endtask

  task handle_jal();
    branch_taken = 1;
    branch_target = program_counter +
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
    branch_taken = 0;
    alu_input2 = 0;
    branch_target = 0;
    load_address = 0;
    store_address = 0;
    store_data = 0;
    case (decoded_instruction.opcode)
      OPCODE_ARITHMETIC_IMMEDIATE: handle_arithmetic_immediate();
      OPCODE_ARITHMETIC: handle_arithmetic();
      OPCODE_BRANCH: handle_branch();
      OPCODE_JALR: handle_jalr();
      OPCODE_JAL: handle_jal();
      OPCODE_LOAD: handle_load();
      OPCODE_STORE: handle_store();
      default: begin
      end
    endcase
  end

  //====================================================================================
  // Arithmetic Logic Unit
  //====================================================================================
  arithmetic_logic_unit alu_inst (
      .input1(rs1_value),
      .input2(alu_input2),
      .decoded_instruction(decoded_instruction),
      .result(alu_result)
  );

  // Output assignments
  assign axis_execute_to_memory.tdata.decoded_instruction = decoded_instruction;
  assign axis_execute_to_memory.tdata.rs1_value = rs1_value;
  assign axis_execute_to_memory.tdata.rs2_value = rs2_value;
  assign axis_execute_to_memory.tdata.alu_result = alu_result;
  assign axis_execute_to_memory.tdata.branch_taken = branch_taken;
  assign axis_execute_to_memory.tdata.branch_target = branch_target;
  assign axis_execute_to_memory.tvalid = axis_decode_to_execute.tvalid;
  assign axis_decode_to_execute.tready = axis_execute_to_memory.tready;

endmodule
