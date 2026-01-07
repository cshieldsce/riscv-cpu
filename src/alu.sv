import riscv_pkg::*;
module ALU (
    input  logic [31:0] A, B,
    input  logic [3:0]  ALUControl,
    output logic [31:0] Result,
    output logic        Zero
);
    // Create a wire for the shift amount (lower 5 bits of B)
    // This fixes the "constant selects" error in Icarus Verilog.
    logic [4:0] shamt;
    assign shamt = B[4:0];

    always_comb begin
        case (ALUControl)
            ALU_AND: Result = A & B;
            ALU_OR:  Result = A | B;
            ALU_ADD: Result = A + B;
            ALU_SUB: Result = A - B;

            // Set Less Than (Signed)
            ALU_SLT: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            
            // Set Less Than (Unsigned) - New
            ALU_SLTU: Result = (A < B) ? 32'd1 : 32'd0;
            
            ALU_XOR: Result = A ^ B;
            
            // Shifts - New (Shift amount is lower 5 bits of B)
            ALU_SLL: Result = A << shamt;
            ALU_SRL: Result = A >> shamt;
            ALU_SRA: Result = $signed(A) >>> shamt; // Arithmetic shift preserves sign

            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0); // Assign directly to Zero

endmodule