module RegFile (
    input logic clk, RegWrite,
    input logic [4:0] rs1, rs2, rd,
    input logic [31:0] WriteData,
    output logic [31:0] ReadData1, ReadData2
);

    // Register storage
    logic [31:0] register_memory [0:31]; // RISC-V register 0 must always be zero

    // Read operation
    assign ReadData1 = (rs1 == 5'b0) ? 32'b0 : register_memory[rs1]; //If rs1 = 0, output 0, else output register_memory[rs1]
    assign ReadData2 = (rs2 == 5'b0) ? 32'b0 : register_memory[rs2]; //If rs2 = 0, output 0, else output register_memory[rs2]

    // Write operation
    always_ff @(posedge clk) begin
        if (RegWrite && (rd != 5'b0)) begin //Only write if RegWrite is high AND register 0 must be zero
            register_memory[rd] <= WriteData; // *Non blocking bc always_ff*
        end
    end


endmodule