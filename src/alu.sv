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
    parameter OP_SLT  = 4'b0111; // Set Less Than (Signed)
    parameter OP_SLTU = 4'b1000; // Set Less Than (Unsigned)
    parameter OP_XOR  = 4'b1001;
    parameter OP_SLL  = 4'b1010; // Shift Left Logical
    parameter OP_SRL  = 4'b1011; // Shift Right Logical
    parameter OP_SRA  = 4'b1100; // Shift Right Arithmetic

    // Create a wire for the shift amount (lower 5 bits of B)
    // This fixes the "constant selects" error in Icarus Verilog.
    logic [4:0] shamt;
    assign shamt = B[4:0];

    always_comb begin
        case (ALUControl)
            OP_AND: Result = A & B;
            OP_OR:  Result = A | B;
            OP_ADD: Result = A + B;
            OP_SUB: Result = A - B;

            // Set Less Than (Signed)
            OP_SLT: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            
            // Set Less Than (Unsigned) - New
            OP_SLTU: Result = (A < B) ? 32'd1 : 32'd0;
            
            OP_XOR: Result = A ^ B;
            
            // Shifts - New (Shift amount is lower 5 bits of B)
            OP_SLL: Result = A << shamt;
            OP_SRL: Result = A >> shamt;
            OP_SRA: Result = $signed(A) >>> shamt; // Arithmetic shift preserves sign

            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0); // Assign directly to Zero

endmodule