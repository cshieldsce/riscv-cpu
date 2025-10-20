module IF_Stage (
    input logic clk, rst,
    output logic [31:0] instruction_out,
    output logic [31:0] pc_out
);

    logic [31:0] next_pc;
    PC pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc),
        .pc_out(pc_out)
    );

    InstructionMemory imem_inst (
        .Address(pc_out),
        .Instruction(instruction_out)
    );

    // Add PC + 4
    assign next_pc = pc_out + 32'd4;

endmodule