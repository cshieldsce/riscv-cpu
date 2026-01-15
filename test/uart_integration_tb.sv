import riscv_pkg::*;

module uart_integration_tb;

    logic clk, rst;

    // Memory interface signals
    logic [ALEN-1:0] imem_addr;
    logic [31:0]     imem_data; 
    logic            imem_en;
    
    logic [ALEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_rdata, dmem_wdata;
    logic dmem_we;
    logic [3:0] dmem_be;
    logic [2:0] dmem_funct3;
    logic [LED_WIDTH-1:0] leds_out;
    
    wire                  uart_tx_out;

    // Use small clock count for fast simulation
    localparam TEST_CLKS_PER_BIT = 10;

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
        .uart_tx_wire()
    );

    // External Data memory instance
    DataMemory dmem_ext (
        .clk(clk),
        .MemWrite(dmem_we),
        .be(dmem_be),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out(),
        .uart_tx_wire(uart_tx_out) 
    );

    // Override UART parameter
    defparam dmem_ext.uart_inst.CLKS_PER_BIT = TEST_CLKS_PER_BIT;

    // Clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("uart_integration.vcd");
        $dumpvars(0, uart_integration_tb);

        // --- MANUAL PROGRAM (Brute force nops instead of branch) ---
        // 0: li x1, 0x80000000
        imem_inst.rom_memory[0] = 32'h800000b7; 
        
        // 4: li x2, 0x41 ('A')
        imem_inst.rom_memory[1] = 32'h04100113;
        // 8: sw x2, 4(x1) -> Send 'A'
        imem_inst.rom_memory[2] = 32'h0020a223;
        
        // WAIT 200 cycles (50 instructions * 4 cycles/inst avg with stalls)
        for (int i=3; i<150; i++) imem_inst.rom_memory[i] = 32'h00000013;
        
        // li x2, 0x42 ('B')
        imem_inst.rom_memory[150] = 32'h04200113;
        // sw x2, 4(x1) -> Send 'B'
        imem_inst.rom_memory[151] = 32'h0020a223;

        // WAIT after 'B'
        for (int i=152; i<250; i++) imem_inst.rom_memory[i] = 32'h00000013;

        // Finish
        imem_inst.rom_memory[250] = 32'h00100113; // li x2, 1
        imem_inst.rom_memory[251] = 32'h800010b7; // li x1, 0x80001000
        imem_inst.rom_memory[252] = 32'h0020a023; // sw x2, 0(x1)

        for (int i=253; i<300; i++) imem_inst.rom_memory[i] = 32'h00000013;

        // --- SIMULATION ---
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        
        $display("Starting UART Integration Test (No Polling)...");

        fork
            uart_receiver();
        join_none

        // Wait ample time
        repeat(10000) @(posedge clk);

        $display("Error: Program did not finish via tohost.");
        $finish;
    end

    // Instruction memory instance
    InstructionMemory imem_inst (
        .clk(clk),
        .en(imem_en),
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    task uart_receiver;
        logic [7:0] rx_data;
        forever begin
            @(negedge uart_tx_out); 
            repeat(TEST_CLKS_PER_BIT + TEST_CLKS_PER_BIT/2) @(posedge clk);
            
            for (int i=0; i<8; i++) begin
                rx_data[i] = uart_tx_out;
                repeat(TEST_CLKS_PER_BIT) @(posedge clk);
            end
            
            $display("[UART RECEIVE] Got Char: %c (0x%h) at time %t", rx_data, rx_data, $time);
        end
    endtask

endmodule
