module ControlUnit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic RegWrite,
    output logic [3:0] ALUControl,
    output logic ALUSrc,
    output logic MemWrite,
    output logic [1:0] MemToReg, // Select write-back data
    output logic Branch
);

    parameter OP_ADD = 4'b0010;
    parameter OP_SUB = 4'b0110;

    always_comb begin
        // Default control signals
        RegWrite = 1'b0;
        ALUControl = 4'b0000;
        ALUSrc = 1'b0;
        MemWrite = 1'b0;
        MemToReg = 2'b00;
        Branch = 1'b0;

        // Since the opcode is shared we check funct3 and funct7 to determine the specific operation
        case (opcode)

            // Handle R-type instructions
            7'b0110011: begin 
                RegWrite = 1'b1;
                ALUSrc = 1'b0;    // Use ReadData2
                MemToReg = 2'b00; // Write ALUResult to RegFile

                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: ALUControl = OP_ADD; // add
                    {7'b0100000, 3'b000}: ALUControl = OP_SUB; // sub
                    default: ALUControl = 4'b0000;
                endcase
            end

            // Handle I-type instructions (addi)
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                MemToReg = 2'b00;
                ALUControl = OP_ADD;
            end
            
            // Handle I-type instructions (Load Word)
            7'b0000011: begin 
                RegWrite = 1'b1; // 'lw' writes to a register
                ALUSrc = 1'b1; // Use Immediate for address offset
                MemToReg = 2'b01; // Write data from memory to RegFile
                ALUControl = OP_ADD; // ALU calculates rs1 + imm
            end

            // Handle S-type instructions (Store Word)
            7'b0100011: begin
                ALUSrc = 1'b1; // Use Immediate for address offset
                MemWrite = 1'b1; // 'sw' writes to memory
                ALUControl = OP_ADD; // ALU calculates rs1 + imm
            end

            // Handle B-type instructions (Branch Equal)
            7'b1100011: begin
                Branch = 1'b1; // 'beq' instruction
                ALUSrc = 1'b0; // Use ReadData2
                ALUControl = OP_SUB; // ALU performs subtraction for comparison
            end

        endcase
    end

endmodule