module PC (
    input logic clk, rst,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out = 32'd0
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_out <= 32'd0;
        end else begin
            pc_out <= pc_in;
        end
    end

endmodule