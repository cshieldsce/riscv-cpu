import riscv_pkg::*;

module bram_integration_tb;

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
        .leds_out(leds_out)
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
        .leds_out() 
    );

    // Clock generator
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("bram_integration.vcd");
        $dumpvars(0, bram_integration_tb);

        // --- MANUAL PROGRAM LOAD ---
        // 0: addi x1, x0, 10  (x1 = 10)
        imem_inst.rom_memory[0] = 32'h00a00093;
        // 4: sw x1, 4(x0)     (Mem[4] = 10)
        imem_inst.rom_memory[1] = 32'h00102223;
        // 8: lw x2, 4(x0)     (x2 = 10) - Tests BRAM Read Latency
        imem_inst.rom_memory[2] = 32'h00402103;
        // C: add x3, x2, x2   (x3 = 20) - Tests Load-Use Stall + Forwarding
        imem_inst.rom_memory[3] = 32'h002101b3;
        // 10: nop
        imem_inst.rom_memory[4] = 32'h00000013;
        // 14: nop
        imem_inst.rom_memory[5] = 32'h00000013;
        // 18: nop
        imem_inst.rom_memory[6] = 32'h00000013;

        // --- SIMULATION ---
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;
        
        $display("Starting BRAM Integration Test...");

        // Wait enough cycles for completion
        repeat(20) @(posedge clk);

        // --- CHECKS ---
        $display("Checking Results...");
        
        // 1. Check Data Memory Write
        if (dmem_inst.ram_memory[1] !== 32'h0000000a) begin // Addr 4 / 4 = index 1
            $error("Memory Write Failed. Addr 4 = %h, Expected 0000000a", dmem_inst.ram_memory[1]);
        end else begin
            $display("PASS: Memory Write (sw)");
        end

        // 2. Check Register File (Internal Probe)
        // Accessing RegFile inside CPU -> ID_Stage -> RegFile
        // Path: cpu_inst.id_stage_inst.reg_file_inst.rf
        
        // Check x1 (10)
        if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[1] !== 32'd10) 
            $error("Reg x1 Mismatch. Got %d, Expected 10", cpu_inst.id_stage_inst.reg_file_inst.register_memory[1]);
        else
            $display("PASS: Reg x1 (addi)");

        // Check x2 (10) - Loaded from Mem
        if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[2] !== 32'd10) 
            $error("Reg x2 Mismatch. Got %d, Expected 10", cpu_inst.id_stage_inst.reg_file_inst.register_memory[2]);
        else
            $display("PASS: Reg x2 (lw - BRAM Read)");

        // Check x3 (20) - Result of forwarding
        if (cpu_inst.id_stage_inst.reg_file_inst.register_memory[3] !== 32'd20) 
            $error("Reg x3 Mismatch. Got %d, Expected 20", cpu_inst.id_stage_inst.reg_file_inst.register_memory[3]);
        else
            $display("PASS: Reg x3 (add - Forwarding from WB)");

        $finish;
    end

endmodule
