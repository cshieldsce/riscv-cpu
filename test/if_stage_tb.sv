module if_stage_tb;

    logic clk, rst;
    logic [31:0] pc_out;
    logic [31:0] instruction;

    // Set PC value to increment by 4
    logic [31:0] next_pc;
    assign next_pc = pc_out + 32'd4;

    PC pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc),
        .pc_out(pc_out)
    );

    InstructionMemory imem_inst (
        .Address(pc_out),
        .Instruction(instruction)
    );

    // Clock Generation
    initial begin
        clk = 0;
    end
    always begin
        #5 clk = ~clk;
    end

    initial begin
        $display("Starting IF Stage Testbench...");

        // Reset the PC
        rst = 1;
        repeat (2) @(posedge clk);
        rst = 0;
        #1;

        // First clock edge (PC = 0)
        @(posedge clk);
        #1;

        // Check if we fetched the first instruction (add x3, x1, x2)
        if (instruction == 32'h002081b3) begin
            $display("PASS: Fetched instruction 0 correctly at PC=0.");
        end else begin
            $error("FAIL: Fetched %h instead of 002081b3 at PC=0", instruction);
        end

        // Second clock edge (PC = 4)
        @(posedge clk);
        #1;

        // Check if we fetched the first instruction (sub x5, x3, x4)
        if (instruction == 32'h0041f2b3) begin
            $display("PASS: Fetched instruction 1 correctly at PC=4.");
        end else begin
            $error("FAIL: Fetched %h instead of 0041f2b3 at PC=4", instruction);
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule