import riscv_pkg::*;

module ALU (
    input  logic [XLEN-1:0] A, B,
    input  alu_op_t         ALUControl,
    output logic [XLEN-1:0] Result,
    output logic            Zero
);
    // Create a wire for the shift amount (log2(XLEN) bits of B)
    logic [$clog2(XLEN)-1:0] shamt;
    assign shamt = B[$clog2(XLEN)-1:0];

    always_comb begin
        case (ALUControl)
            ALU_AND: Result = A & B;
            ALU_OR:  Result = A | B;
            ALU_ADD: Result = A + B;
            ALU_SUB: Result = A - B;

            // Set Less Than (Signed)
            ALU_SLT: Result = ($signed(A) < $signed(B)) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};
            
            // Set Less Than (Unsigned)
            ALU_SLTU: Result = (A < B) ? {{XLEN-1{1'b0}}, 1'b1} : {XLEN{1'b0}};
            
            ALU_XOR: Result = A ^ B;
            
            // Shifts
            ALU_SLL: Result = A << shamt;
            ALU_SRL: Result = A >> shamt;
            ALU_SRA: Result = $signed(A) >>> shamt; // Arithmetic shift preserves sign

            default: Result = {XLEN{1'b0}};
        endcase
    end

    assign Zero = (Result == {XLEN{1'b0}});

endmodule