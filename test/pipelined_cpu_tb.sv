module pipelined_cpu_tb;

    logic clk;
    logic rst;
    
    // Module-level variable for filename
    reg [255:0] test_file;

    // Instantiate the Pipelined CPU
    PipelinedCPU cpu_inst (
        .clk(clk),
        .rst(rst)
    );

    // Clock Generation
    initial begin
        clk = 0;
    end
    always begin
        #5 clk = ~clk;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        // Dynamic Test Loading
        if ($value$plusargs("TEST=%s", test_file)) begin
            $display("Loading Test: %0s", test_file);
            $readmemh(test_file, cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end else begin
            $display("Loading Default: mem/branch_test.mem");
            $readmemh("mem/branch_test.mem", cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end        
        
        // Reset and Run
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
        
        // FIX 1: Increase runtime!
        // Fibonacci takes many cycles. 1000 is safe.
        repeat(1000) @(posedge clk);

        $display("-------------------------------------------------------------");
        $display("Final Register State:");
        $display("x1: %d | x2: %d | x3: %d | x4: %d", 
            cpu_inst.reg_file_inst.register_memory[1],
            cpu_inst.reg_file_inst.register_memory[2], // Result is here
            cpu_inst.reg_file_inst.register_memory[3],
            cpu_inst.reg_file_inst.register_memory[4]);
        $display("-------------------------------------------------------------");

        // --- SMART VERIFICATION ---
        
        // 1. LUI TEST SIGNATURE: x1 must be 0x12345000
        if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
            $display("[PASS] LUI Test: x1 is correct (12345000)");
        end

        // 2. BRANCH TEST SIGNATURE: x3 must be 1 (and x1 is small, not 0x12345...)
        if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) begin
             $display("[PASS] BNE Test (x3=1)");
             
             if (cpu_inst.reg_file_inst.register_memory[4] == 32'd2) $display("[PASS] BEQ Fallthrough (x4=2)");
             else $display("[FAIL] BEQ Fallthrough (x4=%d)", cpu_inst.reg_file_inst.register_memory[4]);

             if (cpu_inst.reg_file_inst.register_memory[5] == 32'd3) $display("[PASS] BLT Test (x5=3)");
             else $display("[FAIL] BLT Test (x5=%d)", cpu_inst.reg_file_inst.register_memory[5]);
        end

        // 3. FIBONACCI TEST SIGNATURE
        // Checks x2 for result 55 (0x37) based on fib_test.asm
        if (cpu_inst.reg_file_inst.register_memory[2] == 32'd55) begin
             $display("[PASS] Fibonacci Test (x2=55)");
        end

        $finish;
    end

endmodule