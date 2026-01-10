module pipelined_cpu_tb;

    logic clk;
    logic rst;
    
    reg [255:0] test_file;

    PipelinedCPU cpu_inst (
        .clk(clk),
        .rst(rst)
    );

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
        
        // DEBUG: Print first few instructions loaded
        $display("First 10 instructions in memory:");
        for (int i = 0; i < 10; i++) begin
            $display("  [%0d]: %h", i, cpu_inst.if_stage_inst.imem_inst.rom_memory[i]);
        end
        
        // Reset and Run
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
        
        // Run with periodic updates
        $display("Starting execution...");
        for (int cycle = 0; cycle < 100; cycle++) begin
            @(posedge clk);
            if (cycle % 10 == 0) begin
                $display("Cycle %0d: PC=%h, x1=%0d, x2=%0d, x3=%0d, x4=%0d", 
                    cycle,
                    cpu_inst.if_pc,
                    cpu_inst.reg_file_inst.register_memory[1],
                    cpu_inst.reg_file_inst.register_memory[2],
                    cpu_inst.reg_file_inst.register_memory[3],
                    cpu_inst.reg_file_inst.register_memory[4]);
            end
        end

        $display("-------------------------------------------------------------");
        $display("Final Register State after 100 cycles:");
        $display("x1: %0d (0x%h)", 
            cpu_inst.reg_file_inst.register_memory[1],
            cpu_inst.reg_file_inst.register_memory[1]);
        $display("x2: %0d (0x%h)", 
            cpu_inst.reg_file_inst.register_memory[2],
            cpu_inst.reg_file_inst.register_memory[2]);
        $display("x3: %0d (0x%h)", 
            cpu_inst.reg_file_inst.register_memory[3],
            cpu_inst.reg_file_inst.register_memory[3]);
        $display("x4: %0d (0x%h)", 
            cpu_inst.reg_file_inst.register_memory[4],
            cpu_inst.reg_file_inst.register_memory[4]);
        $display("x5: %0d (0x%h)", 
            cpu_inst.reg_file_inst.register_memory[5],
            cpu_inst.reg_file_inst.register_memory[5]);
        $display("-------------------------------------------------------------");

        // --- VERIFICATION ---
        
        // 1. LUI TEST
        if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
            $display("[PASS] LUI Test: x1 is correct (12345000)");
        end

        // 2. BRANCH TEST
        if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) begin
             $display("[PASS] BNE Test (x3=1)");
             
             if (cpu_inst.reg_file_inst.register_memory[4] == 32'd2) 
                 $display("[PASS] BEQ Fallthrough (x4=2)");
             else 
                 $display("[FAIL] BEQ Fallthrough (x4=%d)", cpu_inst.reg_file_inst.register_memory[4]);

             if (cpu_inst.reg_file_inst.register_memory[5] == 32'd3) 
                 $display("[PASS] BLT Test (x5=3)");
             else 
                 $display("[FAIL] BLT Test (x5=%d)", cpu_inst.reg_file_inst.register_memory[5]);
        end

        // 3. FIBONACCI TEST
        if (cpu_inst.reg_file_inst.register_memory[2] == 32'd55) begin
             $display("[PASS] Fibonacci Test (x2=55)");
        end else begin
             $display("[FAIL] Fibonacci Test: Expected x2=55, got x2=%0d", 
                 cpu_inst.reg_file_inst.register_memory[2]);
             // Check if it even started
             if (cpu_inst.reg_file_inst.register_memory[1] == 32'd10 &&
                 cpu_inst.reg_file_inst.register_memory[4] == 32'd1) begin
                 $display("  Registers initialized but loop didn't execute properly");
             end
        end

        $finish;
    end

endmodule