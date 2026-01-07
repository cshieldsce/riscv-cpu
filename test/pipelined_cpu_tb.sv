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
        cpu_inst.reg_file_inst.register_memory[1] = 32'd0; 

        // --- RESET ---
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
        #1;

        // --- RUN ---
        // In a pipeline, it takes 5 cycles for the first instruction to finish
        $display("Running for 10 cycles...");
        repeat (10) @(posedge clk);
        #1;

        // --- CHECK RESULTS ---
        if (cpu_inst.reg_file_inst.register_memory[2] == 32'hFFFFFF00) begin
            $display("PASS: Store Byte works correctly!");
        end else begin
            $display("FAIL: Store Byte failed. Got %h", cpu_inst.reg_file_inst.register_memory[2]);
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule