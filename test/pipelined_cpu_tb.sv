module pipelined_cpu_tb;

    logic clk;
    logic rst;

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
        $dumpvars(0, pipelined_cpu_tb); // Dump this testbench
        
        $display("Loading Branch Test...");
        reg [255:0] test_file;
        if ($value$plusargs("TEST=%s", test_file)) begin
            $display("Loading Test: %0s", test_file);
            $readmemh(test_file, cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end else begin
            // Default fallback
            $display("Loading Default: mem/branch_test.mem");
            $readmemh("mem/branch_test.mem", cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end        
        
        // Reset and Run
        rst = 1; repeat(2) @(posedge clk); rst = 0;
        
        // Run enough cycles for all tests to complete
        repeat(20) @(posedge clk);

        // --- VERIFICATION ---
        if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) $display("[PASS] BNE Test (x3=1)");
        else $display("[FAIL] BNE Test (x3=%d)", cpu_inst.reg_file_inst.register_memory[3]);

        if (cpu_inst.reg_file_inst.register_memory[4] == 32'd2) $display("[PASS] BEQ Fallthrough (x4=2)");
        else $display("[FAIL] BEQ Fallthrough (x4=%d)", cpu_inst.reg_file_inst.register_memory[4]);

        if (cpu_inst.reg_file_inst.register_memory[5] == 32'd3) $display("[PASS] BLT Test (x5=3)");
        else $display("[FAIL] BLT Test (x5=%d)", cpu_inst.reg_file_inst.register_memory[5]);

        if (cpu_inst.reg_file_inst.register_memory[6] == 32'd4) $display("[PASS] BGE Fallthrough (x6=4)");
        else $display("[FAIL] BGE Fallthrough (x6=%d)", cpu_inst.reg_file_inst.register_memory[6]);

        $finish;
    end

endmodule