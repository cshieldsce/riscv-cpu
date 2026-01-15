import riscv_pkg::*;

module DataMemory (
    input  logic             clk,
    input  logic             MemWrite, // '1' = Write, '0' = Read
    input  logic [3:0]       be,       // Byte Enable
    input  logic [2:0]       funct3,   // To determine byte/half/word access (Read Formatting)
    input  logic [ALEN-1:0]  Address,
    input  logic [XLEN-1:0]  WriteData,
    output logic [XLEN-1:0]  ReadData, 
    output logic [3:0]       leds_out,
    output logic             uart_tx_wire // Physical TX pin
);
    
    // UART TX Instances
    logic [7:0] uart_data;
    logic       uart_start;
    logic       uart_busy;

    uart_tx #(
        .CLKS_PER_BIT(68) // 115200 at 7.8125MHz (125MHz / 16)
    ) uart_inst (
        .clk(clk),
        .rst(1'b0), // Will use a proper reset in fpga_top
        .tx_start(uart_start),
        .tx_data(uart_data),
        .tx(uart_tx_wire),
        .tx_busy(uart_busy),
        .tx_done()
    );

    // 4MB Memory (1048576 words of 32 bits)
    logic [31:0] ram_memory [0:1048575];
    logic [3:0]  led_reg;
    integer sig_file; 

    logic [ALEN-1:0] word_addr;
    logic [1:0]      byte_offset;
    
    assign word_addr = Address >> 2;          
    assign byte_offset = Address[1:0];        
    assign leds_out = led_reg;

    // --- Pipeline Registers for Read Path ---
    logic [31:0] mem_read_word_reg;
    logic [2:0]  funct3_reg;
    logic [1:0]  byte_offset_reg;
    logic [ALEN-1:0] address_reg;

    // --- Synchronous Read & Write ---
    always_ff @(posedge clk) begin
        // READ: Always read (synchronous BRAM behavior)
        if (word_addr < 1048576) 
            mem_read_word_reg <= ram_memory[word_addr];
        else
            mem_read_word_reg <= 32'b0;

        // Capture control signals for the Read Formatting stage (WB)
        funct3_reg <= funct3;
        byte_offset_reg <= byte_offset;
        address_reg <= Address;

        // Pulse logic for UART
        uart_start <= 1'b0;

        // WRITE
        if (MemWrite) begin
            // 1. MMIO - LEDs (0x80000000)
            if (Address == 32'h8000_0000) begin
                led_reg <= WriteData[3:0]; 
            end
            
            // 2. MMIO - UART (0x80000004)
            else if (Address == 32'h8000_0004) begin
                if (!uart_busy) begin
                    uart_data  <= WriteData[7:0];
                    uart_start <= 1'b1;
                end
            end

            // 3. COMPLIANCE HALT (tohost)
            else if (Address == 32'h80001000) begin
                if (WriteData[0] == 1) begin
                    $display("--- COMPLIANCE TEST PASSED ---");
                end else begin
                    $display("--- COMPLIANCE TEST FAILED (tohost = %0d) ---", WriteData);
                end

                sig_file = $fopen("signature.txt", "w");
                for (int i = 524288; i < 526336; i = i + 1) begin
                    $fwrite(sig_file, "%h\n", ram_memory[i]);
                end
                $fclose(sig_file);
                $finish;
            end

            // 4. RAM Write (Byte Enabled)
            else if (word_addr < 1048575) begin
                logic [31:0] wdata_shifted;
                // Align data: CPU puts data in LSBs, we must shift to correct lane
                wdata_shifted = WriteData << (byte_offset * 8);

                if (be[0]) ram_memory[word_addr][7:0]   <= wdata_shifted[7:0];
                if (be[1]) ram_memory[word_addr][15:8]  <= wdata_shifted[15:8];
                if (be[2]) ram_memory[word_addr][23:16] <= wdata_shifted[23:16];
                if (be[3]) ram_memory[word_addr][31:24] <= wdata_shifted[31:24];
            end
        end
    end

    // --- READ FORMATTING (Combinational, using Registered Data) ---
    
    localparam PAD_BYTE = XLEN - 8;
    localparam PAD_HALF = XLEN - 16;
    localparam PAD_WORD = XLEN - 32;

    logic [XLEN-1:0] lb_0, lb_1, lb_2, lb_3;
    logic [XLEN-1:0] lh_0, lh_1, lh_2;
    logic [XLEN-1:0] lbu_0, lbu_1, lbu_2, lbu_3;
    logic [XLEN-1:0] lhu_0, lhu_1, lhu_2;
    logic [XLEN-1:0] lw_0;

    assign lb_0 = {{ (PAD_BYTE){mem_read_word_reg[7]} },  mem_read_word_reg[7:0]};
    assign lb_1 = {{ (PAD_BYTE){mem_read_word_reg[15]} }, mem_read_word_reg[15:8]};
    assign lb_2 = {{ (PAD_BYTE){mem_read_word_reg[23]} }, mem_read_word_reg[23:16]};
    assign lb_3 = {{ (PAD_BYTE){mem_read_word_reg[31]} }, mem_read_word_reg[31:24]};

    assign lh_0 = {{ (PAD_HALF){mem_read_word_reg[15]} }, mem_read_word_reg[15:0]};
    assign lh_1 = {{ (PAD_HALF){mem_read_word_reg[23]} }, mem_read_word_reg[23:8]};
    assign lh_2 = {{ (PAD_HALF){mem_read_word_reg[31]} }, mem_read_word_reg[31:16]};

    assign lbu_0 = {{ (PAD_BYTE){1'b0} }, mem_read_word_reg[7:0]};
    assign lbu_1 = {{ (PAD_BYTE){1'b0} }, mem_read_word_reg[15:8]};
    assign lbu_2 = {{ (PAD_BYTE){1'b0} }, mem_read_word_reg[23:16]};
    assign lbu_3 = {{ (PAD_BYTE){1'b0} }, mem_read_word_reg[31:24]};

    assign lhu_0 = {{ (PAD_HALF){1'b0} }, mem_read_word_reg[15:0]};
    assign lhu_1 = {{ (PAD_HALF){1'b0} }, mem_read_word_reg[23:8]};
    assign lhu_2 = {{ (PAD_HALF){1'b0} }, mem_read_word_reg[31:16]};

    assign lw_0 = {{ (PAD_WORD){mem_read_word_reg[31]} }, mem_read_word_reg};

    always_comb begin
        ReadData = {XLEN{1'b0}}; 
        
        // MMIO Reads
        if (address_reg == 32'h8000_0008) begin
            // UART Status Register: bit 0 is busy
            ReadData = {{ (XLEN-1){1'b0} }, uart_busy};
        end
        else begin
            case (funct3_reg)
                F3_BYTE: begin 
                    case (byte_offset_reg)
                        2'b00: ReadData = lb_0;
                        2'b01: ReadData = lb_1;
                        2'b10: ReadData = lb_2;
                        2'b11: ReadData = lb_3;
                    endcase
                end
                F3_HALF: begin 
                    case (byte_offset_reg)
                        2'b00: ReadData = lh_0;
                        2'b01: ReadData = lh_1;
                        2'b10: ReadData = lh_2;
                        default: ReadData = 32'hdeadbeef; 
                    endcase
                end
                F3_LBU: begin 
                    case (byte_offset_reg)
                        2'b00: ReadData = lbu_0;
                        2'b01: ReadData = lbu_1;
                        2'b10: ReadData = lbu_2;
                        2'b11: ReadData = lbu_3;
                    endcase
                end
                F3_LHU: begin 
                    case (byte_offset_reg)
                        2'b00: ReadData = lhu_0;
                        2'b01: ReadData = lhu_1;
                        2'b10: ReadData = lhu_2;
                        default: ReadData = 32'hdeadbeef; 
                    endcase
                end
                default: begin // LW
                    if (byte_offset_reg == 2'b00)
                        ReadData = lw_0;
                    else
                        ReadData = 32'hdeadbeef;
                end
            endcase
        end
    end

endmodule