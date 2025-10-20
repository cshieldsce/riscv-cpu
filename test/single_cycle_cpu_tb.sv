module single_cycle_cpu_tb;

    logic clk;
    logic rst;

    logic [31:0] result_x3;
    logic [31:0] result_x5;

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

        // Reset the CPU (PC = 0)
        rst = 1;
        repeat (2) @(posedge clk); // Hold for 2 clock cycles
        rst = 0;
        #1;

        // Let the CPU run
        // Cycle 1: Fetches 'add', PC -> 4
        // Cycle 2: Fetches 'sub', 'add' completes. PC -> 8
        // Cycle 3: 'sub' completes
        $display("CPU running...");
        repeat (3) @(posedge clk); // Run for 3 clock cycles
        #1;

        // Our program was:
        // 1. add x3, x1, x2  (x1=10, x2=0) -> x3 should be 10
        // 2. sub x5, x3, x4  (x3=10, x4=5) -> x5 should be 5

        // Read the values from the register file's memory
        result_x3 = cpu_inst.reg_file_inst.register_memory[3];
        result_x5 = cpu_inst.reg_file_inst.register_memory[5];

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

        $display("Testbench Finished.");
        $finish;
    end

endmodule