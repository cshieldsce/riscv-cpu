import riscv_pkg::*;
module DataMemory (
    input  logic        clk,
    input  logic        MemWrite, // '1' = Write, '0' = Read
    input  logic [2:0]  funct3,   // To determine byte/half/word access
    input  logic [31:0] Address,
    input  logic [31:0] WriteData,
    output logic [31:0] ReadData, 
    output logic [3:0]  leds_out
);
    
    // 4KB Memory (1024 words of 32 bits)
    logic [31:0] ram_memory [0:1023];
    logic [3:0]  led_reg;

    // Alignment signals
    logic [31:0] word_addr;
    logic [1:0]  byte_offset;

    assign word_addr = {2'b0, Address[31:2]}; // Word-aligned address
    assign byte_offset = Address[1:0];        // Byte offset within the word

    // --- READ ---
    assign ReadData = (word_addr < 1024) ? ram_memory[word_addr] : 32'b0;
    always_comb begin
        ReadData = 32'b0; // Default
        if (word_addr < 1024) begin
            logic [31:0] raw_word;
            raw_word = ram_memory[word_addr];
            case (funct3)
                F3_BYTE: begin // Load Byte (lb)
                    case (byte_offset)
                        2'b00: ReadData = {{24{raw_word[7]}}, raw_word[7:0]};
                        2'b01: ReadData = {{24{raw_word[15]}}, raw_word[15:8]};
                        2'b10: ReadData = {{24{raw_word[23]}}, raw_word[23:16]};
                        2'b11: ReadData = {{24{raw_word[31]}}, raw_word[31:24]};
                    endcase
                end
                F3_HALF: begin // Load Half-word (lh)
                    case (byte_offset[1])
                        1'b0: ReadData = {{16{raw_word[15]}}, raw_word[15:0]};
                        1'b1: ReadData = {{16{raw_word[31]}}, raw_word[31:16]};
                    endcase
                end
                F3_BU: begin // Load Byte Unsigned (lbu)
                    case (byte_offset)
                        2'b00: ReadData = {24'b0, raw_word[7:0]};
                        2'b01: ReadData = {24'b0, raw_word[15:8]};
                        2'b10: ReadData = {24'b0, raw_word[23:16]};
                        2'b11: ReadData = {24'b0, raw_word[31:24]};
                    endcase
                end
                F3_HU: begin // Load Half-word Unsigned (lhu)
                    case (byte_offset[1])
                        1'b0: ReadData = {16'b0, raw_word[15:0]};
                        1'b1: ReadData = {16'b0, raw_word[31:16]};
                    endcase
                end
                default: begin // Load Word (lw)
                    ReadData = raw_word;
                end
    
    assign leds_out = led_reg;

    // --- WRITE ---
    always_ff @( posedge clk ) begin
        if (MemWrite) begin
            // 1. MMIO: Writing to 0x80000000 controls LEDs
            if (Address == 32'h8000_0000) begin
                led_reg <= WriteData[3:0]; // Update only lower 4 bits for LEDs
            end
            // 2. Normal RAM: Handle Sizes
            else if (word_addr < 1024) begin
                case (funct3)
                    F3_BYTE: begin // Store Byte (sb)
                        case (byte_offset)
                            2'b00: ram_memory[word_addr][7:0]   <= WriteData[7:0];
                            2'b01: ram_memory[word_addr][15:8]  <= WriteData[7:0];
                            2'b10: ram_memory[word_addr][23:16] <= WriteData[7:0];
                            2'b11: ram_memory[word_addr][31:24] <= WriteData[7:0];
                        endcase
                    end
                    F3_HALF: begin // Store Half-word (sh)
                        case (byte_offset[1])
                            1'b0: ram_memory[word_addr][15:0] <= WriteData[15:0];
                            1'b1: ram_memory[word_addr][31:16] <= WriteData[15:0];
                        endcase
                    end
                    default: begin // Store Word (sw)
                        ram_memory[word_addr] <= WriteData; // Write a full word (4 bytes)
                    end
                endcase
            end
        end
    end
endmodule