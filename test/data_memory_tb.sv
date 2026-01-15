import riscv_pkg::*;

module data_memory_tb;
    logic            tb_clk;
    logic            tb_MemWrite;
    logic [3:0]      tb_be;
    logic [2:0]      tb_funct3;
    logic [ALEN-1:0] tb_Address;
    logic [XLEN-1:0] tb_WriteData;
    logic [XLEN-1:0] tb_ReadData;
    logic [3:0]      tb_leds_out;

    DataMemory dut (
        .clk(tb_clk),
        .MemWrite(tb_MemWrite),
        .be(tb_be),
        .funct3(tb_funct3),
        .Address(tb_Address),
        .WriteData(tb_WriteData),
        .ReadData(tb_ReadData),
        .leds_out(tb_leds_out)
    );

    initial tb_clk = 0;
    always #5 tb_clk = ~tb_clk;

    initial begin
        $dumpfile("dmem_tb.vcd");
        $dumpvars(0, data_memory_tb);

        // Init
        tb_MemWrite = 0;
        tb_be = 0;
        tb_funct3 = F3_WORD;
        tb_Address = 0;
        tb_WriteData = 0;
        
        // Init memory
        dut.ram_memory[64] = 32'h0;

        @(negedge tb_clk);

        // Test 1: Word Write at 0x100
        $display("Test 1: Word Write");
        tb_Address = 32'h100;
        tb_WriteData = 32'h12345678;
        tb_MemWrite = 1;
        tb_be = 4'b1111; 
        
        #1;
        $display("TB: MemWrite=%b Address=%h BE=%b", tb_MemWrite, tb_Address, tb_be);
        
        @(posedge tb_clk);
        // Write happens here
        
        // Test 2: Synchronous Read of Word
        #1;
        $display("Test 2: Word Read");
        tb_MemWrite = 0;
        tb_Address = 32'h100;
        tb_funct3 = F3_WORD;
        
        @(posedge tb_clk); // Read Address Latch
        #2; // Wait for output
        
        assert_val(tb_ReadData, 32'h12345678, "Read Word");

        // Test 3: Byte Write
        $display("Test 3: Byte Write at 0x101");
        tb_Address = 32'h101;
        tb_WriteData = 32'hAA; 
        tb_MemWrite = 1;
        tb_be = 4'b0010; 
        
        @(posedge tb_clk);
        
        // Test 4: Read modified word
        #1;
        $display("Test 4: Read modified word");
        tb_MemWrite = 0;
        tb_Address = 32'h100;
        tb_funct3 = F3_WORD;
        
        @(posedge tb_clk);
        #2;
        assert_val(tb_ReadData, 32'h1234AA78, "Read Modified Word");

        // Test 5: Byte Read Signed
        $display("Test 5: Byte Read Signed");
        tb_Address = 32'h101;
        tb_funct3 = F3_BYTE;
        
        @(posedge tb_clk);
        #2;
        assert_val(tb_ReadData, 32'hFFFFFFAA, "Read Byte Signed");

        // Test 6: Byte Read Unsigned
        $display("Test 6: Byte Read Unsigned");
        tb_Address = 32'h101;
        tb_funct3 = F3_LBU;
        
        @(posedge tb_clk);
        #2;
        assert_val(tb_ReadData, 32'h000000AA, "Read Byte Unsigned");

        $display("Data Memory Tests Done.");
        $finish;
    end

    task assert_val(input [31:0] val, input [31:0] exp, input string msg);
        if (val !== exp) begin
            $error("%s: Expected %h, got %h", msg, exp, val);
        end else begin
            $display("%s: PASS", msg);
        end
    endtask

endmodule