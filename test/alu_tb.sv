module alu_tb;
    logic [31:0] a_in;
    logic [31:0] b_in;
    logic [3:0]  alu_control;
    logic [31:0] result_out;
    logic        zero_out;

    ALU dut (
        .A(a_in),
        .B(b_in),
        .ALUControl(alu_control),
        .Result(result_out),
        .Zero(zero_out)
    );

    initial begin
        $display("Starting ALU Testbench..");

        // Test ADD operation (eg. 5 + 10 = 15)
        a_in = 32'd5;
        b_in = 32'd10;
        alu_control = 4'b0010; // ADD

        #10; // Wait for 10 time units

        if (result_out == 32'd15) begin
            $display("PASS: ADD Test. (5 + 10 = 15)");
        end else begin
            $error("FAIL: ADD Test. Expected=15 but got Result=%d, Zero=%b", result_out, zero_out);
        end

        // Test SUB operation equal to 0 (eg. 7 - 7 = 0)
        a_in = 32'd7;
        b_in = 32'd7;
        alu_control = 4'b0110; // SUB

        #10; // Wait for 10 time units

        if (result_out == 32'd0) begin
            $display("PASS: SUB Test. ( 7- 7 = 0)");
        end else begin
            $error("FAIL: SUB Test. Expected=0 but got Result=%d, Zero=%b", result_out, zero_out);
        end

        // Test AND operation (eg. 12 & 10 = 8)
        a_in = 32'd12; // 1100 in binary
        b_in = 32'd10; // 1010 in binary
        alu_control = 4'b0000; // AND

        #10; // Wait for 10 time units

        if (result_out == 32'd8) begin
            $display("PASS: AND Test. (12 & 10 = 8)");
        end else begin
            $error("FAIL: AND Test. Expected=8 but got Result=%d, Zero=%b", result_out, zero_out);
        end

        // Test OR operation (eg. 12 | 10 = 14)
        a_in = 32'd12; // 1100 in binary
        b_in = 32'd10; // 1010 in binary
        alu_control = 4'b0001; // OR

        #10; // Wait for 10 time units

        if (result_out == 32'd14) begin
            $display("PASS: OR Test. (12 | 10 = 14)");
        end else begin
            $error("FAIL: OR Test. Expected=14 but got Result=%d, Zero=%b", result_out, zero_out);
        end  

        $display("Testbench Finished.");
        $finish;
    end

endmodule