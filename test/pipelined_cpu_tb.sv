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
        //cpu_inst.reg_file_inst.register_memory[2] = 32'd0;

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

        $display("Register x1: %d (Expected 10)", cpu_inst.reg_file_inst.register_memory[1]);
        $display("Register x2: %d (Expected 20)", cpu_inst.reg_file_inst.register_memory[2]);
        
        if (cpu_inst.reg_file_inst.register_memory[2] == 32'd20)
            $display("PASS: Data Hazard handled correctly!");
        else
            $display("FAIL: Data Hazard detected! Read old value.");
        
        // --- VERIFY ---
        // We will check the results manually in the simulation output/waveform for now.
        // $display("Final PC: %h", cpu_inst.if_pc);
        // $display("Register x1: %d (Expected 10)", cpu_inst.reg_file_inst.register_memory[1]);
        // $display("Register x2: %d (Expected 20)", cpu_inst.reg_file_inst.register_memory[2]);
        // $display("Register x3: %d (Expected 30)", cpu_inst.reg_file_inst.register_memory[3]);


        $display("Testbench Finished.");
        $finish;
    end

endmodule