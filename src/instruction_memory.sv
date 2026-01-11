module InstructionMemory (
    input logic [31:0] Address,
    output logic [31:0] Instruction
);

    // Allocate 16KB to handle hex file addresses up to 0x3FFF
    // This gives us 4096 words (indices 0-4095)
    logic [31:0] rom_memory [0:4095];

    // Initialize memory
    initial begin
        for (int i = 0; i < 4096; i = i + 1) begin
            rom_memory[i] = 32'h00000013; // NOP instruction
        end
    end

    // Combinational read logic
    logic [31:0] word_addr;
    assign word_addr = Address >> 2;
    
    // Bounds checking
    assign Instruction = (word_addr < 4096) ? rom_memory[word_addr] : 32'h00000013;

endmodule