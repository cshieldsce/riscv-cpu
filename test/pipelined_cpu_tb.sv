import riscv_pkg::*;

module pipelined_cpu_tb;

    logic clk, rst;
    reg [2047:0] test_file;

    // Memory interface signals
    logic [ALEN-1:0] imem_addr;
    logic [31:0]     imem_data; // Instruction is always 32 bits
    logic            imem_en;   // Instruction Memory Enable
    
    logic [ALEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_rdata, dmem_wdata;
    logic dmem_we;
    logic [3:0] dmem_be;
    logic [2:0] dmem_funct3;
    logic [LED_WIDTH-1:0] leds_out;
    logic                 uart_tx_wire;

    // CPU instance
    PipelinedCPU cpu_inst (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_en(imem_en),
        .dmem_addr(dmem_addr),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_be(dmem_be),
        .dmem_funct3(dmem_funct3),
        .leds_out(leds_out),
        .uart_tx_wire(uart_tx_wire)
    );

    // Instruction memory instance
    InstructionMemory imem_inst (
        .clk(clk),
        .en(imem_en),
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    // Data memory instance
    DataMemory dmem_inst (
        .clk(clk),
        .MemWrite(dmem_we),
        .be(dmem_be),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out(),
        .uart_tx_wire(uart_tx_wire)
    );

    // Clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        // Load test program from command line argument
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
        $display("\nFirst 4 instructions in memory:");
        $display("  [0x00]: %h", imem_inst.rom_memory[0]);
        $display("  [0x04]: %h", imem_inst.rom_memory[1]);
        $display("  [0x08]: %h", imem_inst.rom_memory[2]);
        $display("  [0x0C]: %h", imem_inst.rom_memory[3]);
        
        // Apply reset
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
                
        $display("Waiting for tohost write...\n");
        
        // Timeout mechanism
        fork
            begin : timeout_block
                #50000000;
                $display("\n--- Simulation Timeout! tohost not written. ---");
                $finish;
            end
            begin : main_simulation
                // Runs until $finish from DataMemory
            end
        join_none
        
        $display("[*] Simulation ended.");
        $display("-----------------------------------------------\n");

        wait(0);  // Block forever
    end

endmodule