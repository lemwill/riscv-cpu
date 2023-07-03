
package common;

    localparam REGISTER_WIDTH = 32;
    localparam REGISTER_DEPTH = 32;

    typedef enum logic [6:0] {
        I_TYPE = 7'b0010011, 
        R_TYPE = 7'b0110011,
        S_TYPE = 7'b0100011,
        B_TYPE = 7'b1100011,
        U_TYPE = 7'b0110111,
        J_TYPE = 7'b1101111
    } OpCode;

    typedef enum logic [2:0] {
        ADDI = 'h0,
        XORI = 'h4,
        ORI = 'h6,
        ANDI = 'h7,
        SLLI = 'h1,
        SRLI = 'h5,
        SLTI = 'h2,
        SLTIU = 'h3
    } Funct3;

    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        Funct3 funct3;
        logic [4:0] rd;
    } r_type_t;
    
    typedef struct packed {
        logic [11:0] imm;
        logic [4:0] rs1;
        Funct3 funct3;
        logic [4:0] rd;
    } i_type_t;
    
    typedef struct packed {
        union packed {
            r_type_t r_type;
            i_type_t i_type;
        } instr;
        OpCode opcode;
    } instruction_t;
    


endpackage


