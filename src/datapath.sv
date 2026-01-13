module DataPath (
    input logic clk, RegWrite,
    input  logic [3:0]  ALUControl,
    input logic[4:0] rs1, rs2, rd,
    input logic [31:0] PC,         
    input logic [1:0]  MemToReg,   
    input logic [31:0] ReadDataMem,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteBackData
);

    logic [31:0] ReadData1, ReadData2;

    // --- WRITEBACK MUX ---
    always_comb begin
        case (MemToReg)
            2'b00: WriteBackData = ALUResult;       // R-Type, I-Type
            2'b01: WriteBackData = ReadDataMem;     // Load (LW)
            2'b10: WriteBackData = PC + 4;          // JAL / JALR (Return Address)
            default: WriteBackData = 32'b0;
        endcase
    end

    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .WriteData(WriteBackData), // Write selected result back to register file
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    ALU alu_inst (
        .A(ReadData1),
        .B(ReadData2), 
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero() 
    );

endmodule