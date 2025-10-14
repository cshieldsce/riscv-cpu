module ALU (
    input  logic [31:0] A, B,
    input  logic [3:0]  ALUControl,
    output logic [31:0] Result,
    output logic        Zero
);

    // Define ALU operations
    parameter OP_AND = 4'b0000;
    parameter OP_OR  = 4'b0001;
    parameter OP_ADD = 4'b0010;
    parameter OP_SUB = 4'b0110;

    always_comb begin
        case (ALUControl)
            OP_AND: Result = A & B;
            OP_OR: Result = A | B;
            OP_ADD: Result = A + B;
            OP_SUB: Result = A - B;
            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0); // Assign directly to Zero

endmodule