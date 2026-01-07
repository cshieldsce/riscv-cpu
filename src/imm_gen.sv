import riscv_pkg::*;
module ImmGen (
    input  logic [31:0] instruction,
    input  logic [6:0]  opcode,
    output logic [31:0] imm_out
);

    logic [31:0] imm_I; // For I-type (addi, lw)
    logic [31:0] imm_S; // For S-type (sw)
    logic [31:0] imm_B; // For B-type (beq)
    logic [31:0] imm_J; // For J-type (jal)

    // I-type Immediate 
    // Immediate is bits [31:20]. Sign-extend from bit [31].
    assign imm_I = { {20{instruction[31]}}, instruction[31:20] };

    // S-Type Immediate
    // Immediate is split: [31:25] and [11:7]
    assign imm_S = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] };

    // B-Type Immediate
    // Immediate is split: [31], [7], [30:25], [11:8], with a 0 as LSB
    assign imm_B = {{19{instruction[31]}}, 
                    instruction[31], 
                    instruction[7], 
                    instruction[30:25], 
                    instruction[11:8], 1'b0};

    // J-Type Immediate (JAL)
    // Immediate is split: [31], [19:12], [20], [30:21], with a 0 as LSB
    assign imm_J = {{11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0};

    // Output mux based on opcode
    always_comb begin
        case (opcode)
            OP_I_TYPE: // I-type (addi)
                imm_out = imm_I;
            OP_LOAD: // I-type (lw)
                imm_out = imm_I;
            OP_STORE: // S-type (sw)
                imm_out = imm_S;
            OP_BRANCH: // B-type (beq)
                imm_out = imm_B;
            OP_JAL: // J-type (jal)
                imm_out = imm_J;
            default:
                imm_out = 32'd0; // Default case
        endcase
    end

endmodule