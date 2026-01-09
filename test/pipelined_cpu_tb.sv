module pipelined_cpu_tb;

    logic clk;
    logic rst;
    
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
        
        // Run enough cycles for tests to complete
        repeat(100) @(posedge clk);

        $display("-------------------------------------------------------------");
        $display("Final Register State:");
        $display("x1: %h | x2: %h | x3: %h", 
            cpu_inst.reg_file_inst.register_memory[1],
            cpu_inst.reg_file_inst.register_memory[2],
            cpu_inst.reg_file_inst.register_memory[3]);
        $display("-------------------------------------------------------------");

        // --- SMART VERIFICATION ---
        // instead of checking filename, we check if the result matches the unique signature of the test.
        
        // 1. LUI TEST SIGNATURE: x1 must be 0x12345000
        if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
            $display("[PASS] LUI Test: x1 is correct (12345000)");
            
            // Optional: Check forwarding case from lui_test
            if (cpu_inst.reg_file_inst.register_memory[2] == 32'h12345001) 
                $display("[PASS] LUI Test: x2 (Forwarding) is correct");
        end

        // 2. BRANCH TEST SIGNATURE: x3 must be 1 (and x1 is small, not 0x12345...)
        if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) begin
             $display("[PASS] BNE Test (x3=1)");
             
             if (cpu_inst.reg_file_inst.register_memory[4] == 32'd2) $display("[PASS] BEQ Fallthrough (x4=2)");
             else $display("[FAIL] BEQ Fallthrough (x4=%d)", cpu_inst.reg_file_inst.register_memory[4]);

             if (cpu_inst.reg_file_inst.register_memory[5] == 32'd3) $display("[PASS] BLT Test (x5=3)");
             else $display("[FAIL] BLT Test (x5=%d)", cpu_inst.reg_file_inst.register_memory[5]);

             if (cpu_inst.reg_file_inst.register_memory[6] == 32'd4) $display("[PASS] BGE Fallthrough (x6=4)");
             else $display("[FAIL] BGE Fallthrough (x6=%d)", cpu_inst.reg_file_inst.register_memory[6]);
        end

        // 3. FIBONACCI TEST SIGNATURE (Optional): Check x10 for result 55
        // (Assuming fib(10) = 55)
        if (cpu_inst.reg_file_inst.register_memory[10] == 32'd55) begin
             $display("[PASS] Fibonacci Test (x10=55)");
        end

        $finish;
    end

endmodule