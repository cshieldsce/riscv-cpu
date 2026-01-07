package riscv_pkg;

    // --- OPCODES (RV32I) ---
    typedef enum logic [6:0] {
        OP_R_TYPE   = 7'b0110011, // add, sub, sll...
        OP_I_TYPE   = 7'b0010011, // addi, slti...
        OP_LOAD     = 7'b0000011, // lb, lh, lw...
        OP_STORE    = 7'b0100011, // sb, sh, sw...
        OP_BRANCH   = 7'b1100011, // beq, bne...
        OP_JAL      = 7'b1101111, // jal
        OP_JALR     = 7'b1100111, // jalr
        OP_LUI      = 7'b0110111, // lui (Load Upper Immediate)
        OP_AUIPC    = 7'b0010111, // auipc (Add Upper Immediate to PC)
        OP_SYSTEM   = 7'b1110011  // ecall, csrrw...
    } opcode_t;

    // --- ALU OPERATIONS ---
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0010,
        ALU_SUB  = 4'b0110,
        ALU_AND  = 4'b0000,
        ALU_OR   = 4'b0001,
        ALU_XOR  = 4'b1001,
        ALU_SLL  = 4'b1010,
        ALU_SRL  = 4'b1011,
        ALU_SRA  = 4'b1100,
        ALU_SLT  = 4'b0111,
        ALU_SLTU = 4'b1000
    } alu_op_t;

    // --- FUNCT3 CODES (Data Size) ---
    typedef enum logic [2:0] {
        F3_BYTE  = 3'b000, // lb, sb
        F3_HALF  = 3'b001, // lh, sh
        F3_WORD  = 3'b010, // lw, sw
        F3_IM    = 3'b011, // sltu, sltiu
        F3_BU    = 3'b100, // lbu
        F3_HU    = 3'b101,  // lhu
        F3_OR    = 3'b110, // or, ori
        F3_AND   = 3'b111  // and, andi
    } funct3_mem_t;

endpackage