module uart_tx_tb;

    logic       clk;
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx;
    logic       tx_busy;
    logic       tx_done;

    // Use a small number for simulation speed
    localparam CLKS_PER_BIT = 4;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    initial clk = 0;
    always #5 clk = ~clk; // 10ns period

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        // Timeout Safety Net
        fork
            begin
                #5000; 
                $display("Error: Simulation Timeout.");
                $finish;
            end
            begin
                run_test();
            end
        join
    end

    task run_test;
        rst = 1;
        tx_start = 0;
        tx_data = 0;
        
        repeat(5) @(posedge clk);
        rst = 0;
        
        // Wait for a negedge to set signals safely
        @(negedge clk);
        $display("Sending 0x41 ('A')...");
        tx_data = 8'h41;
        tx_start = 1;
        
        // Wait for one posedge for DUT to see it
        @(posedge clk);
        #1;
        if (tx_busy !== 1) $error("Error: tx_busy should be high now");
        tx_start = 0;

        // --- CHECK SEQUENCE ---
        // We are currently in START_BIT (just entered at posedge)
        
        // 1. Start Bit (Low)
        // Wait 3 more cycles to be in the middle of the 4-cycle bit
        repeat(2) @(posedge clk);
        check_bit(0, "Start Bit");

        // 2. Data Bits (LSB First: 1, 0, 0, 0, 0, 0, 1, 0)
        
        // Bit 0: 1
        wait_bit_period(); 
        check_bit(1, "Data Bit 0");

        // Bit 1: 0
        wait_bit_period();
        check_bit(0, "Data Bit 1");

        // Bit 2: 0
        wait_bit_period();
        check_bit(0, "Data Bit 2");

        // Bit 3: 0
        wait_bit_period();
        check_bit(0, "Data Bit 3");

        // Bit 4: 0
        wait_bit_period();
        check_bit(0, "Data Bit 4");

        // Bit 5: 0
        wait_bit_period();
        check_bit(0, "Data Bit 5");

        // Bit 6: 1
        wait_bit_period();
        check_bit(1, "Data Bit 6");

        // Bit 7: 0
        wait_bit_period();
        check_bit(0, "Data Bit 7");

        // 3. Stop Bit (High)
        wait_bit_period();
        check_bit(1, "Stop Bit");

        // Wait for done
        wait(tx_done == 1);
        $display("Transaction Complete.");
        
        repeat(2) @(posedge clk);
        if (tx_busy !== 0) $error("Error: tx_busy should be low now");

        $display("UART Test Passed.");
        $finish;
    endtask

    task wait_bit_period;
        repeat(CLKS_PER_BIT) @(posedge clk);
    endtask

    task check_bit(input logic expected, input string name);
        #1; // Offset from edge
        if (tx !== expected) begin
            $error("%s Error: Expected %b, Got %b at time %t", name, expected, tx, $time);
        end else begin
            $display("%s: %b (OK)", name, tx);
        end
    endtask

endmodule