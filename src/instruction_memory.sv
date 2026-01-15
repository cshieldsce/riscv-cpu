import riscv_pkg::*;

module InstructionMemory (
    input  logic            clk,
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [31:0]     Instruction
);

    // 4MB to handle huge tests
    logic [31:0] rom_memory [0:1048575];

    // Initialize memory
    initial begin
        for (int i = 0; i < 1048576; i = i + 1) begin
            rom_memory[i] = 32'h00000013; // NOP instruction
        end
    end

    // Combinational read logic
    logic [ALEN-1:0] word_addr;
    assign word_addr = Address >> 2;
    
    // Synchronous read logic
    always_ff @(posedge clk) begin
        if (en) begin
            Instruction <= (word_addr < 1048576) ? rom_memory[word_addr] : 32'h00000013;
        end
    end

endmodule
