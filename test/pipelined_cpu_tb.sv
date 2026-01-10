module pipelined_cpu_tb;

    logic clk;
    logic rst;
    
    reg [255:0] test_file;

    PipelinedCPU cpu_inst (
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
        $dumpfile("waveform.vcd");
        $dumpvars(0, pipelined_cpu_tb);
        
        if ($value$plusargs("TEST=%s", test_file)) begin
            $display("Loading Test: %0s", test_file);
            $readmemh(test_file, cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end else begin
            $display("Loading Default: mem/branch_test.mem");
            $readmemh("mem/branch_test.mem", cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end        
        
        $display("First 12 instructions in memory:");
        for (int i = 0; i < 12; i++) begin
            $display("  [0x%02h]: %h", i*4, cpu_inst.if_stage_inst.imem_inst.rom_memory[i]);
        end
        
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
        
        $display("\nStarting execution...\n");
        for (int cycle = 0; cycle < 150; cycle++) begin
            @(posedge clk);
            #1; // Wait for signals to settle
            
            if (cycle < 30 || cycle % 10 == 0) begin
                $display("=== Cycle %0d ===", cycle);
                $display("  PC=%h, Instruction=%h", 
                    cpu_inst.if_pc,
                    cpu_inst.if_instruction);
                $display("  Registers: x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d", 
                    cpu_inst.reg_file_inst.register_memory[1],
                    cpu_inst.reg_file_inst.register_memory[2],
                    cpu_inst.reg_file_inst.register_memory[3],
                    cpu_inst.reg_file_inst.register_memory[4],
                    cpu_inst.reg_file_inst.register_memory[5]);
                    
                // Show EX stage details
                $display("  EX Stage: Branch=%b Jump=%b PCSrc=%b", 
                    cpu_inst.id_ex_branch,
                    cpu_inst.id_ex_jump,
                    cpu_inst.pcsrc);
                    
                if (cpu_inst.id_ex_branch || cpu_inst.id_ex_jump) begin
                    $display("    ALU inputs: A=%h B=%h", 
                        cpu_inst.alu_in_a,
                        cpu_inst.ex_alu_b_input);
                    $display("    ALU result=%h Zero=%b", 
                        cpu_inst.ex_alu_result,
                        cpu_inst.ex_zero);
                end
                
                $display("  Hazards: stall_if=%b stall_id=%b flush_ex=%b flush_id=%b",
                    cpu_inst.stall_if,
                    cpu_inst.stall_id,
                    cpu_inst.flush_ex,
                    cpu_inst.flush_id);
                $display("");
            end
        end

        $display("-------------------------------------------------------------");
        $display("Final Register State:");
        $display("x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d", 
            cpu_inst.reg_file_inst.register_memory[1],
            cpu_inst.reg_file_inst.register_memory[2],
            cpu_inst.reg_file_inst.register_memory[3],
            cpu_inst.reg_file_inst.register_memory[4],
            cpu_inst.reg_file_inst.register_memory[5]);
        $display("-------------------------------------------------------------");

        // VERIFICATION
        if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
            $display("[PASS] LUI Test");
        end

        if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) begin
             $display("[PASS] BNE Test");
        end

        if (cpu_inst.reg_file_inst.register_memory[2] == 32'd55) begin
             $display("[PASS] Fibonacci Test (x2=55)");
        end else begin
             $display("[FAIL] Fibonacci Test: Expected x2=55, got x2=%0d", 
                 cpu_inst.reg_file_inst.register_memory[2]);
        end

        $finish;
    end

endmodule