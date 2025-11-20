module PipelineRegister #(
    parameter WIDTH = 32    //  WIDTH: The number of bits this register needs to store.
                            //         (e.g., 32 for PC, 100+ for ID/EX control signals)
)(
    input logic clk, rst, en, clear, // Control signals 
    input logic [WIDTH-1:0] in, out  // Data from stage to stage
);

    always_ff @(posedge clk) begin
        if (rst) begin
            out <= '0;              // Reset to 0
        end else if (clear) begin
            out <= '0;              // Flush the register (inject a NOP)
        end else if (en) begin
            out <= in;              // Capture input
        end

        // Holding the old value (Stall)
    end

endmodule