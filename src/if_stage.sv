import riscv_pkg::*;

module IF_Stage (
    input  logic            clk, rst,
    input  logic [XLEN-1:0] next_pc_in,
    input  logic [XLEN-1:0] instruction_in,  // External instruction
    output logic [XLEN-1:0] instruction_out,
    output logic [XLEN-1:0] pc_out,
    output logic [XLEN-1:0] pc_plus_4_out
);

    PC pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc_in),
        .pc_out(pc_out)
    );

    // Instruction now comes from external memory
    assign instruction_out = instruction_in;

    assign pc_plus_4_out = pc_out + 32'd4;

endmodule