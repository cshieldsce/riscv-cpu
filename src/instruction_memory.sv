module InstructionMemory (
    input logic [31:0] Address,
    output logic [31:0] Instruction
);

    // Allocate space to store 64 instructions (64 32-bit words)
    logic [31:0] rom_memory [0:63];

    // Initialize memory
    initial begin
        $readmemh("mem/byte_test.mem", rom_memory); //Load file into rom_memory
    end

    // Combinational read logic
    // PC provides a byte address while our memory is word-addressed
    // To fix this we must we right-shift the address by 2 (equilalent to dividing by 4)
    assign Instruction = rom_memory[Address >> 2]; 

endmodule