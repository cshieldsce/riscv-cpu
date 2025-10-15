module DataPath (
    input logic clk, RegWrite,
    input  logic [3:0]  ALUControl,
    input logic[4:0] rs1, rs2, rd
);

    logic [31:0] ReadData1, ReadData2;
    logic [31:0] ALUResult;

    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .WriteData(ALUResult), // Write ALU result back to register file
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