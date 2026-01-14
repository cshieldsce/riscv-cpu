import riscv_pkg::*;

module RegFile (
    input  logic            clk,
    input  logic            RegWrite,
    input  logic [4:0]      rs1, rs2, rd,
    input  logic [XLEN-1:0] WriteData,
    output logic [XLEN-1:0] ReadData1,
    output logic [XLEN-1:0] ReadData2
);

    // Register storage
    logic [XLEN-1:0] register_memory [0:31]; // RISC-V register 0 must always be zero

    // Initialize registers to zero
    initial begin
        for (int i = 0; i < 32; i = i + 1) begin
            register_memory[i] = {XLEN{1'b0}};
        end
    end

    // Read operation with internal bypass/forwarding
    // If we're reading a register that's being written in the same cycle,
    // forward the write data directly (write-to-read bypass)
    always_comb begin
        // ReadData1
        if (rs1 == 5'b0) begin
            ReadData1 = {XLEN{1'b0}};
        end else if (RegWrite && (rd == rs1) && (rd != 5'b0)) begin
            ReadData1 = WriteData; // Internal bypass
        end else begin
            ReadData1 = register_memory[rs1];
        end
        
        // ReadData2
        if (rs2 == 5'b0) begin
            ReadData2 = {XLEN{1'b0}};
        end else if (RegWrite && (rd == rs2) && (rd != 5'b0)) begin
            ReadData2 = WriteData; // Internal bypass
        end else begin
            ReadData2 = register_memory[rs2];
        end
    end

    // Write operation
    always_ff @(posedge clk) begin
        if (RegWrite && (rd != 5'b0)) begin
            register_memory[rd] <= WriteData;
        end
    end

endmodule