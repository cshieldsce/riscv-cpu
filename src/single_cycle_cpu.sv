// This is the top-level module for the complete Single-Cycle RISC-V CPU.
// The logic here represents the full datapath and control for R-type instructions.

module SingleCycleCPU (
    input logic clk, rst
);

    // Signals from Instruction Fetch
    logic [31:0] pc_out;
    logic [31:0] instruction; // Raw 32-bit instruction fetched from memory

    // Decoded instruction fields
    // The RISC-V ISA defines these specific bit locations
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
    logic [2:0] funct3;

    assign opcode = instruction[6:0]; // Bits 0-6
    assign rd = instruction[11:7];    // Bits 7-11
    assign rs1 = instruction[19:15];  // Bits 15-19
    assign rs2 = instruction[24:20];  // Bits 20-24
    assign funct7 = instruction[31:25];
    assign funct3 = instruction[14:12];

    // Signals from Control Unit
    logic RegWrite;
    logic [3:0] ALUControl;
    logic ALUSrc;
    logic ALUZero;
    logic MemWrite;
    logic [1:0] MemToReg;
    logic Branch;

    // 32-bit 'datapath' wires
    logic [31:0] ReadData1;
    logic [31:0] ReadData2;
    logic [31:0] ALUResult;
    logic [31:0] ImmGenOut;
    logic [31:0] ALU_B_Data;
    logic [31:0] MemReadData;
    logic [31:0] WriteData_Mux_Out;

    // PC and Branch logic
    logic [31:0] pc_plus_4;
    logic [31:0] branch_target;
    logic [31:0] pc_next;
    logic PCSrc;


    // Instruction Fetch Stage
    // Fetches the 'instruction' at the current 'pc_out'
    IF_Stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .next_pc_in(pc_next),
        .instruction_out(instruction), // Output the fetched instruction
        .pc_out(pc_out),                // Output the current PC
        .pc_plus_4_out(pc_plus_4)
    );

    // Immediate Generator
    ImmGen imm_gen_inst (
        .instruction(instruction),
        .opcode(opcode),
        .imm_out(ImmGenOut)
    );

    // Control Unit
    // Decodes the 'opcode' and generates the control signals
    ControlUnit control_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .RegWrite(RegWrite),     
        .ALUControl(ALUControl), 
        .ALUSrc(ALUSrc),       
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .Branch(Branch)
    );

    // Register file
    // Reads data from rs1/rs2 and writes the result back to rd
    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),                      // Input address to read from
        .rs2(rs2),                      // Input Address to read from
        .rd(rd),                        // Input address to write to
        .WriteData(WriteData_Mux_Out),  // Data to write (comes from WriteData Mux)
        .ReadData1(ReadData1),          // Output data from rs1
        .ReadData2(ReadData2)           // Output data from rs2
    );

    // ALU B-Input MUX
    // If ALUSrc is 0, it selects ReadData2 (for R-type)
    // If ALUSrc is 1, it selects ImmGenOut (for I-type)
    assign ALU_B_Data = (ALUSrc == 0) ? ReadData2 : ImmGenOut;

    // ALU
    // Performs the calculation
    ALU alu_inst (
        .A(ReadData1),           // Input data from RegFile (rs1)
        .B(ALU_B_Data),          // Input data from RegFile (rs2)
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(ALUZero)              
    );

    // Data Memory
    DataMemory data_memory_inst (
        .clk(clk),
        .MemWrite(MemWrite),
        .Address(ALUResult),    // Address comes from ALU (rs1 + imm)
        .WriteData(ReadData2),  // Data comes from RegFile (rs2)
        .ReadData(MemReadData)  // Data read from memory
    );

    // Write-back MUX
    // Selects the data to be written back into the Register File
    // MemToReg = 00: Select ALU Result (R-type, addi)
    // MemToReg = 01: Select Data from Memory (lw)
    // MemToReg = 10: (Future use: PC+4 for jal)
    assign WriteData_Mux_Out = (MemToReg == 2'b01) ? MemReadData : ALUResult;

    // Branch Logic
    // Determines the next PC based on branch condition
    assign branch_target = pc_out + ImmGenOut;

    // We take the branch (PCSrc) IF the 'Branch' signal is active
    // AND the ALU's 'Zero' flag is high (meaning rs1 == rs2).
    assign PCSrc = Branch & ALUZero;

    // Selects the branch target address if we take the branch,
    // otherwise, just select PC+4.
    assign pc_next = (PCSrc == 1) ? branch_target : pc_plus_4;

endmodule