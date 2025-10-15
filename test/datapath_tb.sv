module datapath_tb;

    logic clk, RegWrite;
    logic [3:0] ALUControl;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] final_result;

    parameter OP_AND = 4'b0000;
    parameter OP_OR  = 4'b0001;
    parameter OP_ADD = 4'b0010;
    parameter OP_SUB = 4'b0110;

    DataPath dut (
        .clk(clk),
        .RegWrite(RegWrite),
        .ALUControl(ALUControl),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd)
    );

    initial begin
        clk = 0;
    end
    always begin
        #5 clk = ~clk;   // Toggle clock every 5 time units
    end                 // '~' operator inverts the single

    initial begin
        $display("Starting Datapath Testbench...");

        // Write initial values to registers x1 and x2
        $display("Initializing registers x1=10, x2=20");

        dut.reg_file_inst.register_memory[1] = 32'd10; // x1 = 10
        dut.reg_file_inst.register_memory[2] = 32'd20; // x2 = 20
        #1;

        // Execute instruction 'add x3, x1, x2'
        @(posedge clk);
        $display("Executing 'add x3, x1, x2");

        RegWrite = 1; // Enable writing
        rs1 = 5'd1;   // Set src to r1 and r2
        rs2 = 5'd2;
        rd = 5'd3;    // Set dest to r3
        ALUControl = OP_ADD;

        @(posedge clk);
        RegWrite = 0; // Stop the operation
        #1;

        //Check if register x3 holds value 30 (10 + 20)
        final_result = dut.reg_file_inst.register_memory[3];

        if (final_result == 32'd30) begin
            $display("PASS: Register x3 contains 30 (10 + 20)");
        end else begin
            $error("FAIL: Expected x3 to be 30, but got %d", final_result);
        end

        $display("Testbench Finished.");
        $finish;

    end
    
endmodule