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

        $display("Starting Pipelined CPU Test...");

        // --- SETUP ---
        // Initialize registers directly
        cpu_inst.reg_file_inst.register_memory[1] = 32'hDEADBEEF; // x1
        cpu_inst.reg_file_inst.register_memory[2] = 32'hDEADBEEF; // x2

        // --- RESET ---
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
        #1;

        // --- RUN ---
        // In a pipeline, it takes 5 cycles for the first instruction to finish
        $display("Running cycles...");
        repeat (15) @(posedge clk);
        #1;

        // CHECK 1: LUI x1, 0x12345
        // Expected: Upper 20 bits = 0x12345, Lower 12 bits = 0.
        if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
            $display("[PASS] LUI Result (x1): %h", cpu_inst.reg_file_inst.register_memory[1]);
        end else begin
            $display("[FAIL] LUI Result (x1): Expected 12345000, Got %h", cpu_inst.reg_file_inst.register_memory[1]);
        end

        // CHECK 2: ADDI x2, x1, 1
        // Expected: 0x12345000 + 1 = 0x12345001
        // This verifies that Forwarding works with the new MUX, or that the stall handled it.
        if (cpu_inst.reg_file_inst.register_memory[2] == 32'h12345001) begin
            $display("[PASS] ADDI/Forwarding Result (x2): %h", cpu_inst.reg_file_inst.register_memory[2]);
        end else begin
            $display("[FAIL] ADDI Result (x2): Expected 12345001, Got %h", cpu_inst.reg_file_inst.register_memory[2]);
        end

        // CHECK 3: SW x2, 0(x0)
        // Verify the value actually made it to Data Memory
        if (cpu_inst.data_memory_inst.ram_memory[0] == 32'h12345001) begin
            $display("[PASS] Memory Write (Addr 0): %h", cpu_inst.data_memory_inst.ram_memory[0]);
        end else begin
            $display("[FAIL] Memory Write (Addr 0): Expected 12345001, Got %h", cpu_inst.data_memory_inst.ram_memory[0]);
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule