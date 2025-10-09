module ALU (
    input  logic [31:0] A, B,
    input  logic [3:0]  ALUControl,
    output logic [31:0] Result,
    output logic        Zero
);

    always_comb begin
        case (ALUControl)
            4'b0000: Result = A & B; // AND
            4'b0001: Result = A | B; // OR
            4'b0010: Result = A + B; // ADD
            4'b0110: Result = A - B; // SUB
            default: Result = 32'b0; // Default case
        endcase
    end

    assign Zero = (Result == 32'b0); // Assign directly to Zero

endmodule