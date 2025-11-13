module single_cycle_cpu_tb;

    logic clk;
    logic rst;

    logic [31:0] result_x1;
    logic [31:0] result_x2;
    logic [31:0] result_x3;
    logic [31:0] result_x4;
    logic [31:0] result_x5;
    logic [31:0] result_x6;
    logic [31:0] result_x7;
    logic [31:0] result_x8;
    logic [31:0] result_x9;

    logic [31:0] val_mem8;

    SingleCycleCPU cpu_inst (
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
        $display("Starting Single-Cycle CPU Test...");

        // We must initialize the registers before the test
        // Force set values in the register file's memory
        $display("Forcing x1=10, x4=5");

        // Set x1 to be 10 and x4 to be 5
        cpu_inst.reg_file_inst.register_memory[1] = 32'd10;
        cpu_inst.reg_file_inst.register_memory[4] = 32'd5;
        cpu_inst.reg_file_inst.register_memory[6] = 32'd4;

        // Reset the CPU (PC = 0)
        rst = 1;
        repeat (2) @(posedge clk); // Hold for 2 clock cycles
        rst = 0;
        #1;

        // Let the CPU run
        // Cycle 1: Fetches 'add', PC -> 4
        // Cycle 2: Fetches 'sub', 'add' completes. PC -> 8
        // Cycle 3: 'sub' completes
        // Cycle 4: etc.
        $display("CPU running...");
        repeat (11) @(posedge clk);
        #1;

        // Our program is as follows:
        // 1. add x3, x1, x2  (x1=10, x2=0) -> x3 should be 10
        // 2. sub x5, x3, x4  (x3=10, x4=5) -> x5 should be 5
        // 3. addi x6, x1, 50 (x1=10, imm=50) -> x6 should be 60
        // 4. sw x5, 8(x0)   (store x5=5 at address 8)
        // 5. lw x7, 8(x0)   (load from address 8 into x9) -> x9 should be 5
        
        // BEQ Testing
        // 6. addi x1, x0, 5  -> x1=5
        // 7. addi x2, x0, 5  -> x2=5
        // 8. beq x1, x2, skip (x1==x2, so branch is TAKEN)
        // 9. addi x3, x0, 100 (This line is SKIPPED)
        // 10. skip: addi x4, x0, 200 -> x4=200

        // Read the values from the register file's memory
        result_x1 = cpu_inst.reg_file_inst.register_memory[1];
        result_x2 = cpu_inst.reg_file_inst.register_memory[2];
        result_x3 = cpu_inst.reg_file_inst.register_memory[3];
        result_x4 = cpu_inst.reg_file_inst.register_memory[4];
        result_x5 = cpu_inst.reg_file_inst.register_memory[5];
        result_x6 = cpu_inst.reg_file_inst.register_memory[6];
        result_x7 = cpu_inst.reg_file_inst.register_memory[7];
        result_x8 = cpu_inst.reg_file_inst.register_memory[8];
        result_x9 = cpu_inst.reg_file_inst.register_memory[9];

        // Read memory values
        val_mem8 = cpu_inst.data_memory_inst.ram_memory[2];

        // Check results (R, I, L, S)
        if (result_x3 != 32'd10) begin
            $error("FAIL: 'add' instruction. Expected x3=10, but got %d.", result_x3);
        end else begin
            $display("PASS: 'add' instruction (x3 = 10) correct.");
        end

        if (result_x5 != 32'd5) begin
            $error("FAIL: 'sub' instruction. Expected x5=5, but got %d.", result_x5);
        end else begin
            $display("PASS: 'sub' instruction (x5 = 5) correct.");
        end

        if (result_x9 != 32'd60) begin
            $error("FAIL: 'addi' instruction. Expected x9=60, but got %d", result_x9);
        end else begin
            $display("PASS: 'addi' instruction (x9 = 60) correct.");
        end

        if (val_mem8 != 32'd5) begin
            $error("FAIL: 'sw'/'lw' instructions. Expected memory[8]=5, but got %d", val_mem8);
        end else begin
            $display("PASS: 'sw'/'lw' instructions (memory[8] = 5) correct.");
        end

        if (result_x7 != 32'd5) begin
            $error("FAIL: 'lw' instruction. Expected x7=5, but got %d", result_x7);
        end else begin
            $display("PASS: 'lw' instruction (x7 = 5) correct.");
        end

        // Check BEQ results
        if (result_x1 != 32'd5) begin
            $error("FAIL: 'addi' instruction. Expected x1=5, but got %d.", result_x1);
        end else begin
            $display("PASS: 'addi' instruction (x1 = 5) correct.");
        end

        if (result_x2 != 32'd5) begin
            $error("FAIL: 'addi' instruction. Expected x2=5, but got %d.", result_x2);
        end else begin
            $display("PASS: 'addi' instruction (x2 = 5) correct.");
        end

        if (result_x3 != 32'd10) begin
            $error("FAIL: 'beq' instruction (skipped). Expected x3=10, but got %d.", result_x3);
        end else begin
            $display("PASS: 'beq' instruction (skipped, x3 = 10) correct.");
        end

        if (result_x4 != 32'd200) begin
            $error("FAIL: 'addi' instruction. Expected x4=200, but got %d.", result_x4);
        end else begin
            $display("PASS: 'addi' instruction (x4 = 200) correct.");
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule