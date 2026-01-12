module IF_Stage (
    input logic clk, rst,
    input logic [31:0] next_pc_in,
    input logic [31:0] instruction_in,  // External instruction
    output logic [31:0] instruction_out,
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out
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