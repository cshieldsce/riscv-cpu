import riscv_pkg::*;

module datapath_tb;

    logic clk, RegWrite;
    alu_op_t ALUControl;
    logic [4:0] rs1, rs2, rd;
    logic [XLEN-1:0] final_result;

    DataPath dut (
        .clk(clk),
        .RegWrite(RegWrite),
        .ALUControl(ALUControl),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .PC({XLEN{1'b0}}),
        .MemToReg(2'b00),
        .ReadDataMem({XLEN{1'b0}}),
        .ALUResult(),
        .WriteBackData()
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

        dut.reg_file_inst.register_memory[1] = 10; // x1 = 10
        dut.reg_file_inst.register_memory[2] = 20; // x2 = 20
        #1;

        // Execute instruction 'add x3, x1, x2'
        @(posedge clk);
        $display("Executing 'add x3, x1, x2");

        RegWrite = 1; // Enable writing
        rs1 = 5'd1;   // Set src to r1 and r2
        rs2 = 5'd2;
        rd = 5'd3;    // Set dest to r3
        ALUControl = ALU_ADD;

        @(posedge clk);
        RegWrite = 0; // Stop the operation
        #1;

        //Check if register x3 holds value 30 (10 + 20)
        final_result = dut.reg_file_inst.register_memory[3];

        if (final_result == 30) begin
            $display("PASS: Register x3 contains 30 (10 + 20)");
        end else begin
            $error("FAIL: Expected x3 to be 30, but got %d", final_result);
        end

        $display("Testbench Finished.");
        $finish;

    end
    
endmodule