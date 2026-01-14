import riscv_pkg::*;

module ImmGen (
    input  logic [31:0]     instruction,
    input  opcode_t         opcode,
    output logic [XLEN-1:0] imm_out
);

    logic [XLEN-1:0] imm_I; // For I-type (addi, lw)
    logic [XLEN-1:0] imm_S; // For S-type (sw)
    logic [XLEN-1:0] imm_B; // For B-type (beq)
    logic [XLEN-1:0] imm_J; // For J-type (jal)
    logic [XLEN-1:0] imm_U; // For U-type (lui, auipc)

    // I-type Immediate 
    // Immediate is bits [31:20]. Sign-extend from bit [31].
    assign imm_I = { {(XLEN-12){instruction[31]}}, instruction[31:20] };

    // S-Type Immediate
    // Immediate is split: [31:25] and [11:7]
    assign imm_S = { {(XLEN-12){instruction[31]}}, instruction[31:25], instruction[11:7] };

    // B-Type Immediate
    // Immediate is split: [31], [7], [30:25], [11:8], with a 0 as LSB
    assign imm_B = { {(XLEN-13){instruction[31]}}, 
                     instruction[31], 
                     instruction[7], 
                     instruction[30:25], 
                     instruction[11:8], 1'b0 };

    // J-Type Immediate (JAL)
    // Immediate is split: [31], [19:12], [20], [30:21], with a 0 as LSB
    assign imm_J = { {(XLEN-21){instruction[31]}},
                     instruction[31],
                     instruction[19:12],
                     instruction[20],
                     instruction[30:21],
                     1'b0 };

    // U-Type Immediate (LUI, AUIPC)
    // Immediate is bits [31:12] shifted left by 12 bits. Sign extended for RV64.
    assign imm_U = { {(XLEN-32){instruction[31]}}, instruction[31:12], 12'b0 };

    // Output mux based on opcode
    always_comb begin
        case (opcode)
            OP_I_TYPE: imm_out = imm_I; // I-type (addi)
            OP_LOAD:   imm_out = imm_I; // I-type (lw)
            OP_JALR:   imm_out = imm_I; // I-type (jalr)
            OP_STORE:  imm_out = imm_S; // S-type (sw)
            OP_BRANCH: imm_out = imm_B; // B-type (beq)
            OP_JAL:    imm_out = imm_J; // J-type (jal)
            OP_LUI:    imm_out = imm_U; // U-type (lui)
            OP_AUIPC:  imm_out = imm_U; // U-type (auipc)
            default:   imm_out = {XLEN{1'b0}}; 
        endcase
    end
endmodule