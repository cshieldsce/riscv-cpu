module fib_test_tb;

    logic clk;
    logic rst;
    logic [31:0] result;

    // Instantiate the CPU
    SingleCycleCPU cpu_inst (
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
        $display("Starting CPU...");

        // --- RESET ---
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
        #1;

        // --- EXECUTE ---
        // The Fibonacci loop takes many cycles.
        // 10 iterations * ~6 instructions/iter = ~60 cycles.
        // We wait 200 cycles to be safe.
        $display("Running Fibonacci program...");
        repeat (200) @(posedge clk);
        #1;

        // --- VERIFY ---
        // The program stores the result (55) into Memory Address 0.
        result = cpu_inst.data_memory_inst.ram_memory[0];

        if (result == 32'd55) begin
            $display("PASS: Fibonacci(10) = %d correct.", result);
        end else begin
            $error("FAIL: Memory[0] expected 55, but got %d", result);
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule