import riscv_pkg::*;

module PC (
    input  logic            clk, rst,
    input  logic [XLEN-1:0] pc_in,
    output logic [XLEN-1:0] pc_out = {XLEN{1'b0}}
);

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_out <= {XLEN{1'b0}};
        end else begin
            pc_out <= pc_in;
        end
    end

endmodule