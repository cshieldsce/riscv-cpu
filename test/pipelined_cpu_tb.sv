module pipelined_cpu_tb;

    logic clk;
    logic rst;
    
    reg [2047:0] test_file;

    // Wires for interconnections
    logic [31:0] imem_addr;
    logic [31:0] imem_data;
    
    logic [31:0] dmem_addr;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_wdata;
    logic        dmem_we;
    logic [3:0]  dmem_be; // Not used by DataMemory in this design, but good to have
    logic [2:0]  dmem_funct3;
    logic [3:0]  leds_out;

    // CPU Instance
    PipelinedCPU cpu_inst (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .dmem_addr(dmem_addr),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_be(dmem_be),
        .dmem_funct3(dmem_funct3),
        .leds_out(leds_out)
    );

    // Instruction Memory Instance
    InstructionMemory imem_inst (
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    // Data Memory Instance
    DataMemory dmem_inst (
        .clk(clk),
        .MemWrite(dmem_we),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out() // Unused in TB for now, or could monitor
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
        
        if ($value$plusargs("TEST=%s", test_file)) begin
            $display("Loading Test: %0s", test_file);
            $readmemh(test_file, imem_inst.rom_memory);
            $readmemh(test_file, dmem_inst.ram_memory);
        end else begin
            $display("Error: No test file specified. Use +TEST=<filename>");
            $finish;
        end

        
        $display("\n-----------------------------------------------");
        $display("[*] Starting execution...");
        $display("\nFirst 12 instructions in memory:");
        $display("  [0x00]: %h", imem_inst.rom_memory[0]);
        $display("  [0x04]: %h", imem_inst.rom_memory[1]);
        $display("  [0x08]: %h", imem_inst.rom_memory[2]);
        $display("  [0x0C]: %h", imem_inst.rom_memory[3]);
        
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
                
        // Run until $finish is called by tohost write in DataMemory
        $display("Waiting for tohost write...\n");
        
        // Add a timeout
        fork
            begin : timeout_block
                #50000000; // Increased timeout
                $display("\n--- Simulation Timeout! tohost not written. ---");
                $finish;
            end
            begin : main_simulation
                // Empty block, simulation runs until $finish from DataMemory
            end
        join_none
        $display("[*] Simulation ended.");
        $display("-----------------------------------------------\n");

        wait(0); // block forever
    end

endmodule
