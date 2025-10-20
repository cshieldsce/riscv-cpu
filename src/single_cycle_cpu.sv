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

    assign opcode = instruction[6:0]; // Bits 0-6
    assign rd = instruction[11:7];    // Bits 7-11
    assign rs1 = instruction[19:15];  // Bits 15-19
    assign rs2 = instruction[24:20];  // Bits 20-24

    // Signals from Control Unit
    logic RegWrite;
    logic [3:0] ALUControl;

    // 32-bit 'datapath' wires
    logic [31:0] ReadData1;
    logic [31:0] ReadData2;
    logic [31:0] ALUResult;

    // Instruction Fetch Stage
    // Fetches the 'instruction' at the current 'pc_out'
    IF_Stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .instruction_out(instruction), // Output the fetched instruction
        .pc_out(pc_out)                // Output the current PC
    );

    // Control Unit
    // Decodes the 'opcode' and generates the control signals
    ControlUnit control_unit_inst (
        .opcode(opcode),
        .RegWrite(RegWrite),    // Output RegWrite signal
        .ALUControl(ALUControl) // Output ALUControl signal
    );

    // Register file
    // Reads data from rs1/rs2 and writes the result back to rd
    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),              // Input address to read from
        .rs2(rs2),              // Input Address to read from
        .rd(rd),                // Input address to write to
        .WriteData(ALUResult),  // Data to write (comes from ALU)
        .ReadData1(ReadData1),  // Output data from rs1
        .ReadData2(ReadData2)   // Output data from rs2
    );

    // ALU
    // This block performs the calculation
    ALU alu_inst (
        .A(ReadData1),           // Input data from RegFile (rs1)
        .B(ReadData2),           // Input data from RegFile (rs2)
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero()                  // Unused for now
    );

endmodule