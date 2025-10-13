module reg_file_tb;
    logic clk, RegWrite;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] WriteData;
    logic [31:0] ReadData1, ReadData2;

    RegFile dut (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .WriteData(WriteData),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    initial begin
        clk = 0; // Initialize clock to 0
    end

    always begin
        #5 clk = ~clk; // Toggle clock every 5 time units
    end                // '~' operator inverts the single

    initial begin
        $display("Starting RegFile Testbench..");

        RegWrite = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        WriteData = 32'b0;

        @(posedge clk); // Wait for positive clock edge
        RegWrite = 1; //Enabling writing
        rd = 5; // Write to register 5
        WriteData = 32'd123; // Write 123 to register 5

        @(posedge clk); // Wait for positive clock edge to complete write
        RegWrite = 0; // Disable writing

        rs1 = 5; // Read from register 5
        #5; // Wait for 5 time units

        if (ReadData1 == 32'd123) begin // Check if the read data matches 123
            $display("PASS: Read back 123 from register x5.");
        end else begin
            $error("FAIL: Expected 123, but got %d", ReadData1);
        end

        $display("Testbench Finished.");
        $finish;
    end

endmodule