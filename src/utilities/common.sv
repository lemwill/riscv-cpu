
package common;

  localparam REGISTER_WIDTH = 32;
  localparam REGISTER_DEPTH = 32;
  localparam BYTE_WIDTH = 8;

  typedef logic [REGISTER_WIDTH-1:0] RegisterValue;

  /*typedef enum logic [6:0] {
        I_TYPE = 7'b0010011, 
        R_TYPE = 7'b0110011,
        S_TYPE = 7'b0100011,
        B_TYPE = 7'b1100011,
        U_TYPE = 7'b0110111,
        J_TYPE = 7'b1101111
    } OpCode;*/

  typedef enum logic [6:0] {
    OP_LUI                  = 7'b0110111,  // Load Upper Immediate
    OP_AUIPC                = 7'b0010111,  // Add Upper Immediate to PC
    OP_JAL                  = 7'b1101111,  // Jump and Link
    OP_JALR                 = 7'b1100111,  // Jump and Link Register
    OP_BRANCH               = 7'b1100011,  // Conditional Branch
    OP_LOAD                 = 7'b0000011,  // Load from Memory
    OP_STORE                = 7'b0100011,  // Store to Memory
    OP_ARITHMETIC_IMMEDIATE = 7'b0010011,  // Arithmetic Immediate
    OP_ARITHMETIC           = 7'b0110011,  // Arithmetic Operand
    OP_MISC_MEMORY          = 7'b0001111,  // Miscellaneous Memory
    OP_SYSTEM               = 7'b1110011,  // System Instruction
    OP_LOAD_FP              = 7'b0000111,  // Load Floating Point
    OP_STORE_FP             = 7'b0100111,  // Store Floating Point
    OP_ATOMIC_MEMORY        = 7'b0101111   // Atomic Memory Operation
  } OpCode;

  typedef enum logic [2:0] {
    BEQ  = 'h0,
    BNE  = 'h1,
    BLT  = 'h4,
    BGE  = 'h5,
    BLTU = 'h6,
    BGEU = 'h7
  } BTypeFunct3;

  typedef enum logic [2:0] {JALR = 'h0} JTypeFunct3;

  typedef enum logic [2:0] {
    ADD_OR_SUB = 'h0,
    XOR = 'h4,
    OR = 'h6,
    AND = 'h7,
    SLL = 'h1,
    SRL_OR_SRA = 'h5,
    SLT = 'h2,
    SLTU = 'h3
  } RTypeFunct3;

  typedef enum logic [2:0] {
    SB = 'h0,
    SH = 'h1,
    SW = 'h2
  } STypeFunct3;

  typedef enum logic [2:0] {
    LB  = 'h0,
    LH  = 'h1,
    LW  = 'h2,
    LBU = 'h4,
    LHU = 'h5
  } FUNC3_LOAD;

  typedef enum logic [2:0] {
    ADDI_OR_JAL = 'h0,
    XORI = 'h4,
    ORI = 'h6,
    ANDI = 'h7,
    SLLI = 'h1,
    SRLI_OR_SRAI = 'h5,
    SLTI = 'h2,
    SLTUI = 'h3
  } ITypeFunct3;

  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    RTypeFunct3 funct3;
    logic [4:0] rd;
  } r_type_t;

  typedef struct packed {
    logic [11:0] immediate;
    logic [4:0]  rs1;
    ITypeFunct3  funct3;
    logic [4:0]  rd;
  } i_type_t;

  typedef struct packed {
    logic [6:0] immediate_11_5;
    logic [4:0] rs2;
    logic [4:0] rs1;
    STypeFunct3 funct3;
    logic [4:0] immediate_4_0;
  } s_type_t;


  typedef struct packed {
    logic [12:12] immediate_12;
    logic [10:5]  immediate_10_5;
    logic [4:0]   rs2;
    logic [4:0]   rs1;
    BTypeFunct3   funct3;
    logic [4:1]   immediate_4_1;
    logic [11:11] immediate_11;
  } b_type_t;

  typedef struct packed {
    logic [20:20] immediate_20;
    logic [10:1]  immediate_10_1;
    logic [11:11] immediate_11;
    logic [19:12] immediate_19_12;
    logic [4:0]   rd;
  } j_type_t;

  typedef struct packed {
    union packed {
      r_type_t r_type;
      i_type_t i_type;
      s_type_t s_type;
      b_type_t b_type;
      j_type_t j_type;
    } instr;
    OpCode opcode;
  } instruction_undecoded_t;


  typedef struct packed {
    union packed {
      logic [11:0]  i_type;
      logic [11:0]  s_type;
      logic [12:1]  b_type;
      logic [31:12] u_type;
      logic [19:0]  j_type;
    } immediate;
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    union packed {
      RTypeFunct3 r_type;
      ITypeFunct3 i_type;
      STypeFunct3 s_type;
      BTypeFunct3 b_type;
    } funct3;
    logic [4:0] rd;
    OpCode opcode;
  } instruction_t;

  typedef struct packed {
    logic [REGISTER_WIDTH-1:0] instruction;
    logic [REGISTER_WIDTH-1:0] program_counter;
    logic branch_taken_prediction;
  } fetch_to_decode_t;

  typedef struct packed {
    instruction_t decoded_instruction;
    RegisterValue rs1_value;
    RegisterValue rs2_value;
    logic [REGISTER_WIDTH-1:0] program_counter;
    logic branch_taken_prediction;
  } decode_to_execute_t;

  typedef struct packed {
    instruction_t decoded_instruction;
    logic [REGISTER_WIDTH-1:0] alu_result;
    logic branch_taken;
    logic [REGISTER_WIDTH-1:0] branch_target;
    RegisterValue rs1_value;
    RegisterValue rs2_value;
  } execute_to_memory_t;

  typedef struct packed {
    instruction_t decoded_instruction;
    logic [REGISTER_WIDTH-1:0] alu_result;
    logic [REGISTER_WIDTH-1:0] branch_target;
    logic [REGISTER_WIDTH-1:0] data_from_memory;
  } memory_to_writeback_t;

  parameter MEM_ADDRESS_WIDTH = 32;

endpackage


