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
    logic [31:0] mem_read_word;
    
    // 1. Extract the word from memory purely with combinational logic
    assign mem_read_word = (word_addr < 1024) ? ram_memory[word_addr] : 32'b0;

    assign word_addr = {2'b0, Address[31:2]}; // Word-aligned address
    assign byte_offset = Address[1:0];        // Byte offset within the word
    assign leds_out = led_reg;

    // --- READ LOGIC ---
    always @(*) begin
        ReadData = 32'b0; 
        if (word_addr < 1024) begin
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
                    case (byte_offset[1])
                        1'b0: ReadData = {{16{mem_read_word[15]}}, mem_read_word[15:0]};
                        1'b1: ReadData = {{16{mem_read_word[31]}}, mem_read_word[31:16]};
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
                    case (byte_offset[1])
                        1'b0: ReadData = {16'b0, mem_read_word[15:0]};
                        1'b1: ReadData = {16'b0, mem_read_word[31:16]};
                    endcase
                end
                default: begin // Load Word (lw)
                    ReadData = mem_read_word;
                end
            endcase
        end
    end

    // --- WRITE LOGIC ---
    logic [31:0] new_word;

    always @(posedge clk) begin
        if (MemWrite) begin
            // 1. MMIO - LEDs
            if (Address == 32'h8000_0000) begin
                led_reg <= WriteData[3:0]; 
            end
            
            // 2. COMPLIANCE HALT
            else if (Address == 32'h8000_0004) begin
                $display("--- COMPLIANCE TEST COMPLETE ---");
                // This creates the file the test suite looks for
                $writememh("memory_dump.hex", ram_memory); 
                $finish;
            end

            // 3. RAM Write
            else if (word_addr < 1024) begin
                new_word = mem_read_word;
                case (funct3)
                    F3_BYTE: begin 
                        case (byte_offset)
                            2'b00: new_word = {mem_read_word[31:8], WriteData[7:0]};
                            2'b01: new_word = {mem_read_word[31:16], WriteData[7:0], mem_read_word[7:0]};
                            2'b10: new_word = {mem_read_word[31:24], WriteData[7:0], mem_read_word[15:0]};
                            2'b11: new_word = {WriteData[7:0], mem_read_word[23:0]};
                        endcase
                    end
                    F3_HALF: begin 
                        case (byte_offset[1])
                            1'b0: new_word = {mem_read_word[31:16], WriteData[15:0]};
                            1'b1: new_word = {WriteData[15:0], mem_read_word[15:0]};
                        endcase
                    end
                    default: begin 
                        new_word = WriteData; 
                    end
                endcase
                
                ram_memory[word_addr] <= new_word; 
            end
        end
    end

endmodule