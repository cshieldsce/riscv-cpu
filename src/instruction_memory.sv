import riscv_pkg::*;

module InstructionMemory (
    input  logic            clk,
    input  logic            en,
    input  logic [ALEN-1:0] Address,
    output logic [31:0]     Instruction
);

    logic [31:0] rom_memory [0:4095]; // 4KB small ROM for hardware test

    // --- HARDWARE TEST PROGRAM ---
    // This runs automatically on the FPGA
    initial begin
        // 0x00: li x1, 0x80000000 (Base MMIO)
        rom_memory[0] = 32'h800000b7;
        // 0x04: li x2, 0x1 (LED value)
        rom_memory[1] = 32'h00100113;
        // 0x08: li x4, 0x21 ('!')
        rom_memory[2] = 32'h02100213;
        
        // --- LOOP START ---
        // 0x0C: sw x2, 0(x1) -> Update LEDs
        rom_memory[3] = 32'h0020a023;
        // 0x10: sw x4, 4(x1) -> Send '!' to UART
        rom_memory[4] = 32'h0040a223;
        
        // 0x14: xori x2, x2, 1 -> Toggle LED 0
        rom_memory[5] = 32'h00114113;
        
        // --- DELAY LOOP ---
        // 0x18: li x3, 1000000 (Adjust for visible blink)
        rom_memory[6] = 32'h000f41b7; // lui x3, 0xF4 (approx 1M)
        
        // 0x1C: addi x3, x3, -1
        rom_memory[7] = 32'hfff18193;
        // 0x20: bne x3, x0, -4 (back to 0x1C)
        rom_memory[8] = 32'hfe019ee3;
        
        // 0x24: jal x0, -24 (back to 0x0C)
        rom_memory[9] = 32'he99ff06f;

        // Fill rest with NOP
        for (int i = 10; i < 4096; i = i + 1) begin
            rom_memory[i] = 32'h00000013;
        end
    end

    logic [ALEN-1:0] word_addr;
    assign word_addr = Address >> 2;
    
    always_ff @(posedge clk) begin
        if (en) begin
            Instruction <= (word_addr < 4096) ? rom_memory[word_addr] : 32'h00000013;
        end
    end

endmodule