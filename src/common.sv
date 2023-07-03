
package common;

    localparam REGISTER_WIDTH = 32;
    localparam REGISTER_DEPTH = 32;

    typedef enum logic [6:0] {
        I_TYPE = 7'b0010011
    } alu_ops;

    typedef enum logic [2:0] {
        ADDI = 'h0,
        XORI = 'h4,
        ORI = 'h6,
        ANDI = 'h7,
        SLLI = 'h1,
        SRLI = 'h5,
        SLTI = 'h2,
        SLTIU = 'h3
    } I_TYPE_FUNCT3;

    typedef struct packed {
        logic [6:0] opcode;
        logic [4:0] rd;
        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [2:0] funct3;
        logic [6:0] funct7;
    } r_type_t;
    
    typedef struct packed {
        logic [6:0] opcode;
        logic [4:0] rd;
        logic [4:0] rs1;
        logic [11:0] imm;
        logic [2:0] funct3;
    } i_type_t;
    
    typedef union packed {
        r_type_t r_type;
        i_type_t i_type;
    } instruction_t;
    
    


endpackage


