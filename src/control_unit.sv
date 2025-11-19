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

    // Define ALU operations
    parameter OP_AND = 4'b0000;
    parameter OP_OR  = 4'b0001;
    parameter OP_ADD = 4'b0010;
    parameter OP_SUB = 4'b0110;
    parameter OP_SLT  = 4'b0111; // Set Less Than (Signed)
    parameter OP_SLTU = 4'b1000; // Set Less Than (Unsigned)
    parameter OP_XOR  = 4'b1001;
    parameter OP_SLL  = 4'b1010; // Shift Left Logical
    parameter OP_SRL  = 4'b1011; // Shift Right Logical
    parameter OP_SRA  = 4'b1100; // Shift Right Arithmetic

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
            7'b0110011: begin 
                RegWrite = 1'b1;
                ALUSrc = 1'b0;    // Use ReadData2
                MemToReg = 2'b00; // Write ALUResult to RegFile

                case (funct3)
                    3'b000: ALUControl = (funct7 == 7'b0000000) ? OP_ADD : OP_SUB;  // add or sub
                    3'b001: ALUControl = OP_SLL;                                    // shift left logical
                    3'b010: ALUControl = OP_SLT;                                    // set less than signed
                    3'b011: ALUControl = OP_SLTU;                                   // set less than unsigned
                    3'b100: ALUControl = OP_XOR;                                    // xor
                    3'b101: ALUControl = (funct7 == 7'b0000000) ? OP_SRL : OP_SRA;  // srl or sra
                    3'b110: ALUControl = OP_OR;                                     // or
                    3'b111: ALUControl = OP_AND;                                    // and
                    default: ALUControl = 4'b0000;
                endcase
            end

            // Handle I-type instructions (addi)
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemToReg = 2'b00;
                ALUControl = OP_ADD;

                case (funct3)
                    3'b000: ALUControl = OP_ADD; // addi
                    3'b010: ALUControl = OP_SLT; // slti
                    3'b011: ALUControl = OP_SLTU; // sltiu
                    3'b100: ALUControl = OP_XOR; // xori
                    3'b110: ALUControl = OP_OR;  // ori
                    3'b111: ALUControl = OP_AND; // andi
                    3'b001: ALUControl = OP_SLL; // slli
                    3'b101: ALUControl = (funct7 == 7'b0000000) ? OP_SRL : OP_SRA; // srli or srai
                    default: ALUControl = OP_ADD;
                endcase
            end
            
            // Handle I-type instructions (Load Word)
            7'b0000011: begin 
                RegWrite = 1'b1;     // 'lw' writes to a register
                ALUSrc = 1'b1;       // Use Immediate for address offset
                MemToReg = 2'b01;    // Write data from memory to RegFile
                ALUControl = OP_ADD; // ALU calculates rs1 + imm
            end

            // Handle S-type instructions (Store Word)
            7'b0100011: begin
                ALUSrc = 1'b1;       // Use Immediate for address offset
                MemWrite = 1'b1;     // 'sw' writes to memory
                ALUControl = OP_ADD; // ALU calculates rs1 + imm
            end

            // Handle B-type instructions (Branch Equal)
            7'b1100011: begin
                Branch = 1'b1;       // 'beq' instruction
                ALUSrc = 1'b0;       // Use ReadData2
                ALUControl = OP_SUB; // ALU performs subtraction for comparison
            end

            // Handle J-type instructions (Jump and Link)
            7'b1101111: begin
                RegWrite = 1'b1;  // 'jal' writes to a register
                Jump = 1'b1;      // Indicate a jump instruction
                MemToReg = 2'b10; // PC+4 for jal
            end

            // Handle J-type instructions (Jump and Link Register)
            7'b1100111: begin
                RegWrite = 1'b1;  // 'jalr' writes to a register
                Jalr = 1'b1;      // Indicate a jump instruction
                ALUSrc = 1'b1;    // Use Immediate for address calculation
                MemToReg = 2'b10; // PC+4 for jalr
                ALUControl = OP_ADD; // ALU calculates rs1 + imm
            end

        endcase
    end

endmodule