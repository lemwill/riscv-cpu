module instruction_decode #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] instruction,
    output instruction_t decoded_instruction
);

  // Extract fields from the instruction.
  assign decoded_instruction.opcode = alu_ops'(instruction[6:0]);
  assign decoded_instruction.rd     = instruction[11:7];
  assign decoded_instruction.rs1    = instruction[19:15];
  assign decoded_instruction.rs2    = instruction[24:20];
  assign decoded_instruction.funct3 = instruction[14:12];
  assign decoded_instruction.funct7 = instruction[31:25];

endmodule
