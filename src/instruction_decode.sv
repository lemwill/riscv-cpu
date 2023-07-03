module instruction_decode #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] instruction,
    output instruction_t decoded_instruction
);

  // Extract fields from the instruction.
  assign decoded_instruction = instruction;

endmodule
