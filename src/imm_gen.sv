module ImmGen (
    input  logic [31:0] instruction,
    output logic [31:0] imm_out
);

    // For I-type, the immediate is in bits [31:20].
    // We sign-extend it by replicating the sign bit (instruction[31])
    // 20 times to fill the upper 20 bits.
    // {20{bit}} is the SystemVerilog "replication" operator.
    assign imm_out = { {20{instruction[31]}}, instruction[31:20] };

endmodule