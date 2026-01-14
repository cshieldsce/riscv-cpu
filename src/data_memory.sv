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
    
    // 4MB Memory (1048576 words of 32 bits)
    logic [31:0] ram_memory [0:1048575];
    logic [3:0]  led_reg;
    integer sig_file; // File handle for signature dump

    // Alignment signals
    logic [31:0] word_addr;
    logic [1:0]  byte_offset;
    logic [31:0] mem_read_word;
    
    // 1. Extract the word from memory purely with combinational logic
    assign mem_read_word = (word_addr < 1048576) ? ram_memory[word_addr] : 32'b0;

    assign word_addr = Address >> 2;          // Word-aligned address
    assign byte_offset = Address[1:0];        // Byte offset within the word
    assign leds_out = led_reg;

    // --- READ LOGIC ---
    always_comb begin
        ReadData = 32'hdeadbeef; // Default value for debugging
        if (word_addr < 1048576) begin
            case (funct3)
                F3_BYTE: begin // Load Byte (lb)
                    case (byte_offset)
                        2'b00: ReadData = {{24{mem_read_word[7]}},  mem_read_word[7:0]};
                        2'b01: ReadData = {{24{mem_read_word[15]}}, mem_read_word[15:8]};
                        2'b10: ReadData = {{24{mem_read_word[23]}}, mem_read_word[23:16]};
                        2'b11: ReadData = {{24{mem_read_word[31]}}, mem_read_word[31:24]};
                    endcase
                end
                F3_HALF: begin // Load Half-word (lh)
                    case (byte_offset)
                        2'b00: ReadData = {{16{mem_read_word[15]}}, mem_read_word[15:0]};
                        2'b01: ReadData = {{16{mem_read_word[23]}}, mem_read_word[23:8]};
                        2'b10: ReadData = {{16{mem_read_word[31]}}, mem_read_word[31:16]};
                        default: ReadData = 32'hdeadbeef; // Should not be taken in tests
                    endcase
                end
                F3_BU: begin // Load Byte Unsigned (lbu)
                    case (byte_offset)
                        2'b00: ReadData = {24'b0, mem_read_word[7:0]};
                        2'b01: ReadData = {24'b0, mem_read_word[15:8]};
                        2'b10: ReadData = {24'b0, mem_read_word[23:16]};
                        2'b11: ReadData = {24'b0, mem_read_word[31:24]};
                    endcase
                end
                F3_HU: begin // Load Half-word Unsigned (lhu)
                    case (byte_offset)
                        2'b00: ReadData = {16'b0, mem_read_word[15:0]};
                        2'b01: ReadData = {16'b0, mem_read_word[23:8]};
                        2'b10: ReadData = {16'b0, mem_read_word[31:16]};
                        default: ReadData = 32'hdeadbeef; // Should not be taken in tests
                    endcase
                end
                default: begin // Load Word (lw) or other
                    if (byte_offset == 2'b00)
                        ReadData = mem_read_word;
                    else
                        ReadData = 32'hdeadbeef; // lw with misaligned address
                end
            endcase
        end
    end

    // --- WRITE LOGIC ---
    always @(posedge clk) begin
        if (MemWrite) begin
            // 1. MMIO - LEDs
            if (Address == 32'h8000_0000) begin
                led_reg <= WriteData[3:0]; 
            end
            
            // 2. COMPLIANCE HALT (tohost)
            else if (Address == 32'h80001000) begin
                if (WriteData[0] == 1) begin
                    $display("--- COMPLIANCE TEST PASSED ---");
                end else begin
                    $display("--- COMPLIANCE TEST FAILED (tohost = %0d) ---", WriteData);
                end

                // Dump signature region to file
                sig_file = $fopen("signature.txt", "w");
                // Dump 8KB starting from 0x200000 (index 524288)
                for (int i = 524288; i < 526336; i = i + 1) begin
                    $fwrite(sig_file, "%h\n", ram_memory[i]);
                end
                $fclose(sig_file);
                $finish;
            end

            // 3. RAM Write
            else if (word_addr < 1048575) begin
                logic [31:0] new_word = mem_read_word;
                case (funct3)
                    F3_BYTE: begin // sb
                        case (byte_offset)
                            2'b00: new_word = {mem_read_word[31:8],  WriteData[7:0]};
                            2'b01: new_word = {mem_read_word[31:16], WriteData[7:0], mem_read_word[7:0]};
                            2'b10: new_word = {mem_read_word[31:24], WriteData[7:0], mem_read_word[15:0]};
                            2'b11: new_word = {WriteData[7:0],        mem_read_word[23:0]};
                        endcase
                    end
                    F3_HALF: begin // sh
                        case (byte_offset)
                            2'b00: new_word = {mem_read_word[31:16], WriteData[15:0]};
                            2'b01: new_word = {mem_read_word[31:24], WriteData[15:0], mem_read_word[7:0]};
                            2'b10: new_word = {WriteData[15:0],      mem_read_word[15:0]};
                            default:; // Misaligned across words, ignore
                        endcase
                    end
                    F3_WORD: begin // sw
                        if (byte_offset == 2'b00)
                            new_word = WriteData;
                    end
                endcase
                ram_memory[word_addr] <= new_word;
            end
        end
    end

endmodule