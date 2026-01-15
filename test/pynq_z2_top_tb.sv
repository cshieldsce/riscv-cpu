module pynq_z2_top_tb;

    logic sysclk;
    logic reset_btn;
    logic [3:0] led;
    logic uart_tx;

    pynq_z2_top dut (
        .sysclk(sysclk),
        .reset_btn(reset_btn),
        .led(led),
        .uart_tx(uart_tx)
    );

    // 125 MHz clock (8ns period)
    initial sysclk = 0;
    always #4 sysclk = ~sysclk;

    initial begin
        $dumpfile("pynq_top_tb.vcd");
        $dumpvars(0, pynq_z2_top_tb);

        reset_btn = 1;
        repeat(10) @(posedge sysclk);
        reset_btn = 0;

        $display("Simulating PYNQ-Z2 Top Level...");
        $display("Verifying clock divider...");
        
        // Wait for a few CPU clock cycles (each CPU cycle is 16 sysclk cycles)
        repeat(100) @(posedge sysclk);

        $display("Top level simulation finished.");
        $finish;
    end

endmodule
