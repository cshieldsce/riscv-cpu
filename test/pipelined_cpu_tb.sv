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
            $display("Loading Default: mem/complex_branch_test.mem");
            $readmemh("mem/complex_branch_test.mem", cpu_inst.if_stage_inst.imem_inst.rom_memory);
        end        
        
        $display("First 12 instructions in memory:");
        for (int i = 0; i < 12; i++) begin
            $display("  [0x%02h]: %h", i*4, cpu_inst.if_stage_inst.imem_inst.rom_memory[i]);
        end
        
        rst = 1;
        repeat(2) @(posedge clk); 
        rst = 0;
        
        $display("\nStarting execution...\n");
        
        // Run with detailed output for first 15 cycles, then sparse output
        for (int cycle = 0; cycle < 150; cycle++) begin
            @(posedge clk);
            #1; // Wait for signals to settle
            
            // Detailed output for first 15 cycles
            if (cycle < 15) begin
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
                    
                // Show pipeline stages
                $display("  Pipeline Stages:");
                $display("    ID/EX: rs1=%0d rs2=%0d rd=%0d RegWrite=%b", 
                    cpu_inst.id_ex_rs1, 
                    cpu_inst.id_ex_rs2,
                    cpu_inst.id_ex_rd,
                    cpu_inst.id_ex_reg_write);
                $display("    EX/MEM: rd=%0d RegWrite=%b ALUResult=%h", 
                    cpu_inst.ex_mem_rd,
                    cpu_inst.ex_mem_reg_write,
                    cpu_inst.ex_mem_alu_result);
                $display("    MEM/WB: rd=%0d RegWrite=%b WriteData=%h", 
                    cpu_inst.mem_wb_rd,
                    cpu_inst.mem_wb_reg_write,
                    cpu_inst.wb_write_data);
                    
                // Show forwarding
                $display("  Forwarding: forward_a=%b forward_b=%b", 
                    cpu_inst.forward_a,
                    cpu_inst.forward_b);
                $display("    ALU inputs: A=%h B=%h (before ALUSrc)", 
                    cpu_inst.alu_in_a,
                    cpu_inst.alu_in_b);
                $display("    ALU result=%h", 
                    cpu_inst.ex_alu_result);
                    
                $display("  Hazards: stall_if=%b stall_id=%b flush_ex=%b flush_id=%b",
                    cpu_inst.stall_if,
                    cpu_inst.stall_id,
                    cpu_inst.flush_ex,
                    cpu_inst.flush_id);
                $display("");
            end
            // Sparse output every 10 cycles after that
            else if (cycle % 10 == 0) begin
                $display("Cycle %0d: PC=%h x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d", 
                    cycle,
                    cpu_inst.if_pc,
                    cpu_inst.reg_file_inst.register_memory[1],
                    cpu_inst.reg_file_inst.register_memory[2],
                    cpu_inst.reg_file_inst.register_memory[3],
                    cpu_inst.reg_file_inst.register_memory[4],
                    cpu_inst.reg_file_inst.register_memory[5]);
            end
        end

        $display("-------------------------------------------------------------");
        $display("Final Register State:");
        $display("x1: %h | x2: %d | x3: %d | x4: %d", 
            cpu_inst.reg_file_inst.register_memory[1],
            cpu_inst.reg_file_inst.register_memory[2], 
            cpu_inst.reg_file_inst.register_memory[3],
            cpu_inst.reg_file_inst.register_memory[4]);
        $display("-------------------------------------------------------------");

        // --- SMART VERIFICATION ---

        // 1. LUI TEST
        if (test_file == "mem/lui_test.mem") begin
            if (cpu_inst.reg_file_inst.register_memory[1] == 32'h12345000) begin
                $display("[PASS] LUI Test: x1 is correct (12345000)");
            end else begin
                $display("[FAIL] LUI Test: Expected 12345000, got %h", cpu_inst.reg_file_inst.register_memory[1]);
            end
        end

        // 2. COMPLEX BRANCH TEST
        else if (test_file == "mem/cbranch_test.mem") begin
            // Check x3 (BNE Result)
            if (cpu_inst.reg_file_inst.register_memory[3] == 32'd1) 
                 $display("[PASS] BNE Test (x3=1)");
            else 
                 $display("[FAIL] BNE Test (x3=%d)", cpu_inst.reg_file_inst.register_memory[3]);

            // Check x4 (BEQ Result)
            if (cpu_inst.reg_file_inst.register_memory[4] == 32'd2) 
                 $display("[PASS] BEQ Fallthrough (x4=2)");
            else 
                 $display("[FAIL] BEQ Fallthrough (x4=%d)", cpu_inst.reg_file_inst.register_memory[4]);

            // Check x5 (BLT Result)
            if (cpu_inst.reg_file_inst.register_memory[5] == 32'd3) 
                 $display("[PASS] BLT Test (x5=3)");
            else 
                 $display("[FAIL] BLT Test (x5=%d)", cpu_inst.reg_file_inst.register_memory[5]);

            // Check x6 (BGE Result)
            if (cpu_inst.reg_file_inst.register_memory[6] == 32'd4) 
                 $display("[PASS] BGE Test (x6=4)");
            else 
                 $display("[FAIL] BGE Test (x6=%d)", cpu_inst.reg_file_inst.register_memory[6]);
        end

        // 3. FIBONACCI TEST
        else if (test_file == "mem/fib_test.mem") begin
            if (cpu_inst.reg_file_inst.register_memory[2] == 32'd55) begin
                 $display("[PASS] Fibonacci Test (x2=55)");
            end else begin
                 $display("[FAIL] Fibonacci Test. Expected 55, got %d", cpu_inst.reg_file_inst.register_memory[2]);
            end
        end
        
        // 4. DEFAULT / OTHER
        else begin
            $display("No automatic verification for: %s", test_file);
        end

        $finish;
    end

endmodule