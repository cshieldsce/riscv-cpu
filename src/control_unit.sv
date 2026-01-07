import riscv_pkg::*;

module ControlUnit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic RegWrite,
    output logic [3:0] ALUControl,
    output logic ALUSrc,
    output logic MemWrite,
    output logic [1:0] MemToReg, // Select write-back data
    output logic Branch,
    output logic Jump,
    output logic Jalr
    
);
    always_comb begin
        // Default control signals
        RegWrite = 1'b0;
        ALUControl = 4'b0000;
        ALUSrc = 1'b0;
        MemWrite = 1'b0;
        MemToReg = 2'b00;
        Branch = 1'b0;
        Jump = 1'b0;
        Jalr = 1'b0;

        // Since the opcode is shared we check funct3 and funct7 to determine the specific operation
        case (opcode)

            // Handle R-type instructions
            OP_R_TYPE: begin 
                RegWrite = 1'b1;
                ALUSrc = 1'b0;    // Use ReadData2
                MemToReg = 2'b00; // Write ALUResult to RegFile

                case (funct3)
                    F3_BYTE: ALUControl = (funct7 == 7'b0000000) ? ALU_ADD : ALU_SUB;  // add or sub
                    F3_HALF: ALUControl = ALU_SLL;                                    // shift left logical
                    F3_WORD: ALUControl = ALU_SLT;                                    // set less than signed
                    F3_IM: ALUControl = ALU_SLTU;                                   // set less than unsigned
                    F3_BU: ALUControl = ALU_XOR;                                    // xor
                    F3_HU: ALUControl = (funct7 == 7'b0000000) ? ALU_SRL : ALU_SRA;  // srl or sra
                    F3_OR: ALUControl = ALU_OR;                                     // or
                    F3_AND: ALUControl = ALU_AND;                                    // and
                    default: ALUControl = 4'b0000;
                endcase
            end

            // Handle I-type instructions (addi)
            OP_I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemToReg = 2'b00;
                ALUControl = ALU_ADD; // Default to addi

                case (funct3)
                    F3_BYTE: ALUControl = ALU_ADD; // addi
                    F3_WORD: ALUControl = ALU_SLT; // slti
                    F3_IM: ALUControl = ALU_SLTU; // sltiu
                    F3_BU: ALUControl = ALU_XOR; // xori
                    F3_OR: ALUControl = ALU_OR;  // ori
                    F3_AND: ALUControl = ALU_AND; // andi
                    F3_HALF: ALUControl = ALU_SLL; // slli
                    F3_HU: ALUControl = (funct7 == 7'b0000000) ? ALU_SRL : ALU_SRA; // srli or srai
                    default: ALUControl = ALU_ADD;
                endcase
            end
            
            // Handle I-type instructions (Load Word)
            OP_LOAD: begin 
                RegWrite = 1'b1;     // 'lw' writes to a register
                ALUSrc = 1'b1;       // Use Immediate for address offset
                MemToReg = 2'b01;    // Write data from memory to RegFile
                ALUControl = ALU_ADD; // ALU calculates rs1 + imm
            end

            // Handle S-type instructions (Store Word)
            OP_STORE: begin
                ALUSrc = 1'b1;       // Use Immediate for address offset
                MemWrite = 1'b1;     // 'sw' writes to memory
                ALUControl = ALU_ADD; // ALU calculates rs1 + imm
            end

            // Handle B-type instructions (Branch Equal)
            OP_BRANCH: begin
                Branch = 1'b1;       // 'beq' instruction
                ALUSrc = 1'b0;       // Use ReadData2
                ALUControl = ALU_SUB; // ALU performs subtraction for comparison
            end

            // Handle J-type instructions (Jump and Link)
            OP_JAL: begin
                RegWrite = 1'b1;  // 'jal' writes to a register
                Jump = 1'b1;      // Indicate a jump instruction
                MemToReg = 2'b10; // PC+4 for jal
            end

            // Handle J-type instructions (Jump and Link Register)
            OP_JALR: begin
                RegWrite = 1'b1;  // 'jalr' writes to a register
                Jalr = 1'b1;      // Indicate a jump instruction
                ALUSrc = 1'b1;    // Use Immediate for address calculation
                MemToReg = 2'b10; // PC+4 for jalr
                ALUControl = ALU_ADD; // ALU calculates rs1 + imm
            end

        endcase
    end

endmodule