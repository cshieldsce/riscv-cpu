import riscv_pkg::*;

module instruction_memory_tb;

    logic            clk;
    logic            en;
    logic [ALEN-1:0] Address;
    logic [31:0]     Instruction;

    InstructionMemory dut (
        .clk(clk),
        .en(en),
        .Address(Address),
        .Instruction(Instruction)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("imem_tb.vcd");
        $dumpvars(0, instruction_memory_tb);

        // Initialize some memory locations directly in the DUT
        dut.rom_memory[0] = 32'hDEADBEEF;
        dut.rom_memory[1] = 32'hCAFEBABE;
        
        en = 0;
        Address = 0;
        
        @(negedge clk);
        
        // Test 1: Read with Enable
        $display("Test 1: Read with Enable");
        Address = 32'h0;
        en = 1;
        @(posedge clk); // Address sampled
        #1; // Wait a bit for prop delay simulation
        if (Instruction !== 32'hDEADBEEF) $error("Mismatch at addr 0. Expected DEADBEEF, got %h", Instruction);
        
        // Test 2: Change Address
        $display("Test 2: Change Address");
        Address = 32'h4;
        en = 1;
        @(posedge clk);
        #1;
        if (Instruction !== 32'hCAFEBABE) $error("Mismatch at addr 4. Expected CAFEBABE, got %h", Instruction);

        // Test 3: Disable Enable (Hold previous value)
        $display("Test 3: Disable Enable");
        en = 0;
        Address = 32'h0; // Change address back to 0, but en is 0
        @(posedge clk);
        #1;
        // Should STILL be CAFEBABE because en was 0
        if (Instruction !== 32'hCAFEBABE) $error("Output changed when disabled! Expected CAFEBABE, got %h", Instruction);
        
        $display("Instruction Memory Tests Done.");
        $finish;
    end

endmodule
