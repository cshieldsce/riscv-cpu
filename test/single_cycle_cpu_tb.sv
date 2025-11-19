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
    logic [31:0] result_x10;
    logic [31:0] result_x11;
    logic [31:0] result_x12;

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

        // --- R, I, Load, Store ---
        $display("CPU running...");
        // 5 instructions: add, sub, addi, sw, lw
        repeat (5) @(posedge clk);
        #1;

        // Read the values from the register file's memory
        result_x3 = cpu_inst.reg_file_inst.register_memory[3];
        result_x5 = cpu_inst.reg_file_inst.register_memory[5];
        result_x6 = cpu_inst.reg_file_inst.register_memory[6];
        result_x7 = cpu_inst.reg_file_inst.register_memory[7];
        result_x9 = cpu_inst.reg_file_inst.register_memory[9];

        // Read memory values
        val_mem8 = cpu_inst.data_memory_inst.ram_memory[2];

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

        // --- Branching ---
        // Next 4 instructions: addi x1, addi x2, beq (taken), addi x4 (at target)
        repeat (4) @(posedge clk);
        #1;

        // Read the values from the register file's memory
        result_x1 = cpu_inst.reg_file_inst.register_memory[1];
        result_x2 = cpu_inst.reg_file_inst.register_memory[2];
        result_x3 = cpu_inst.reg_file_inst.register_memory[3];
        result_x4 = cpu_inst.reg_file_inst.register_memory[4];

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

        // --- Jump (jal) ---
        // Next 4 instructions: addi x1, jal, addi x2 (target), addi x5
        repeat (4) @(posedge clk);
        #1;

        // Read the values from the register file's memory
        result_x1 = cpu_inst.reg_file_inst.register_memory[1];
        result_x2 = cpu_inst.reg_file_inst.register_memory[2];
        result_x3 = cpu_inst.reg_file_inst.register_memory[3];
        result_x4 = cpu_inst.reg_file_inst.register_memory[4];
        result_x5 = cpu_inst.reg_file_inst.register_memory[5];

        if (result_x1 != 32'd10) begin
            $error("FAIL: 'addi' instruction before JAL. Expected x1=10, but got %d.", result_x1);
        end else begin
            $display("PASS: 'addi' instruction before JAL (x1 = 10) correct.");
        end

        if (result_x3 != 32'd48) begin
            $error("FAIL: 'jal' instruction. Expected x3=48, but got %d.", result_x3);
        end else begin
            $display("PASS: 'jal' instruction (x3 = 48) correct.");
        end

        if (result_x2 != 32'd20) begin
            $error("FAIL: 'addi' instruction at jump target. Expected x2=20, but got %d.", result_x2);
        end else begin
            $display("PASS: 'addi' instruction at jump target (x2 = 20) correct.");
        end

        if (result_x5 != 32'd99) begin
            $error("FAIL: 'addi' instruction after jump target. Expected x5=99, but got %d.", result_x5);
        end else begin
            $display("PASS: 'addi' instruction after jump target (x5 = 99) correct.");
        end

        // --- Function call (jalr) ---

        repeat(8) @(posedge clk);
        #1;

        result_x1 = cpu_inst.reg_file_inst.register_memory[1];
        result_x10 = cpu_inst.reg_file_inst.register_memory[10];
        result_x11 = cpu_inst.reg_file_inst.register_memory[11];
        result_x12 = cpu_inst.reg_file_inst.register_memory[12];

        if (result_x1 != 32'd68) begin
            $error("FAIL: 'addi' instruction function call link. Expected x1=72, but got %d.", result_x1);
        end else begin
            $display("PASS: 'addi' instruction function call link (x1 = 72) correct.");
        end

        if (result_x10 != 32'd15) begin
            $error("FAIL: 'addi' instruction function execution. Expected x10=15, but got %d.", result_x10);
        end else begin
            $display("PASS: 'addi' instruction function execution (x10 = 15) correct.");
        end

        if (result_x11 != 32'd1) begin
            $error("FAIL: 'addi' check return. Expected x11=1, but got %d.", result_x11);
        end else begin
            $display("PASS: 'addi' check return (x11 = 1) correct.");
        end

        if (result_x12 != 32'd1) begin
            $error("FAIL: 'addi' after return. Expected x12=1, but got %d.", result_x12);
        end else begin
            $display("PASS: 'addi' after return (x12 = 1) correct.");
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule