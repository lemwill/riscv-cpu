
package common;

    localparam REGISTER_WIDTH = 32;
    localparam REGISTER_DEPTH = 32;
    localparam BYTE_WIDTH = 8;

    /*typedef enum logic [6:0] {
        I_TYPE = 7'b0010011, 
        R_TYPE = 7'b0110011,
        S_TYPE = 7'b0100011,
        B_TYPE = 7'b1100011,
        U_TYPE = 7'b0110111,
        J_TYPE = 7'b1101111
    } OpCode;*/

    typedef enum logic [6:0] {
        OPCODE_LUI                     = 7'b0110111, // Load Upper Immediate
        OPCODE_AUIPC                   = 7'b0010111, // Add Upper Immediate to PC
        OPCODE_JAL                     = 7'b1101111, // Jump and Link
        OPCODE_JALR                    = 7'b1100111, // Jump and Link Register
        OPCODE_BRANCH                  = 7'b1100011, // Conditional Branch
        OPCODE_LOAD                    = 7'b0000011, // Load from Memory
        OPCODE_STORE                   = 7'b0100011, // Store to Memory
        OPCODE_ARITHMETIC_IMMEDIATE    = 7'b0010011, // Arithmetic Immediate
        OPCODE_ARITHMETIC              = 7'b0110011, // Arithmetic Operand
        OPCODE_MISC_MEMORY             = 7'b0001111, // Miscellaneous Memory
        OPCODE_SYSTEM                  = 7'b1110011, // System Instruction
        OPCODE_LOAD_FP                 = 7'b0000111, // Load Floating Point
        OPCODE_STORE_FP                = 7'b0100111, // Store Floating Point
        OPCODE_ATOMIC_MEMORY           = 7'b0101111  // Atomic Memory Operation
    } OpCode;

    typedef enum logic [2:0] {
        BEQ = 'h0,
        BNE = 'h1,
        BLT = 'h4,
        BGE = 'h5,
        BLTU = 'h6,
        BGEU = 'h7
    } BTypeFunct3;

    typedef enum logic [2:0] {
        JALR = 'h0
    } JTypeFunct3;

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
        LB = 'h0,
        LH = 'h1,
        LW = 'h2,
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
        logic [4:0] rs1;
        ITypeFunct3 funct3;
        logic [4:0] rd;
    } i_type_t;


    typedef struct packed {
        logic [11:0] immediate;
        logic [4:0] rs2;
        logic [4:0] rs1;
        STypeFunct3 funct3;
    } s_type_t;
    

    typedef struct packed {
        logic [11:0] immediate;
        logic [4:0] rs2;
        logic [4:0] rs1;
        BTypeFunct3 funct3;
    } b_type_t;

    typedef struct packed {
        logic [19:0] immediate; 
        logic [4:0] rd;
    } j_type_t;


    typedef struct packed {
        logic [6:0] immediate_11_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        STypeFunct3 funct3;
        logic [4:0] immediate_4_0;
    } s_type_undecoded_t;
    
    
    typedef struct packed {
        logic [12:12] immediate_12;
        logic [10:5] immediate_10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        BTypeFunct3 funct3;
        logic [4:1] immediate_4_1;
        logic [11:11] immediate_11;
    } b_type_undecoded_t;

    typedef struct packed {
        logic [20:20] immediate_20;
        logic [10:1] immediate_10_1;
        logic [11:11] immediate_11;
        logic [19:12] immediate_19_12;
        logic [4:0] rd;
    } j_type_undecoded_t;

    typedef struct packed {
        union packed {
            r_type_t r_type;
            i_type_t i_type;
            s_type_undecoded_t s_type;
            b_type_undecoded_t b_type;
            j_type_undecoded_t j_type;
        } instr;
        OpCode opcode;
    } instruction_undecoded_t;


    typedef struct packed {
        union packed {
            r_type_t r_type;
            i_type_t i_type;
            s_type_t s_type;
            b_type_t b_type;
            j_type_t j_type;
        } instr;
        OpCode opcode;
    } instruction_t;
    


endpackage


