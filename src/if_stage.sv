module IF_Stage (
    input logic clk, rst,
    input logic [31:0] next_pc_in,
    output logic [31:0] instruction_out,
    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out
);

    logic [31:0] next_pc;
    PC pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc_in),
        .pc_out(pc_out)
    );

    InstructionMemory imem_inst (
        .Address(pc_out),
        .Instruction(instruction_out)
    );

    // Add PC + 4
    assign pc_plus_4_out = pc_out + 32'd4;

endmodule