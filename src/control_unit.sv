module ControlUnit (
    input logic [6:0] opcode,
    output logic RegWrite,
    output logic [3:0] ALUControl
);

    parameter OP_ADD = 4'b0010;

    always_comb begin
        // Set controls to an idle state (0)
        RegWrite = 1'b0;
        ALUControl = 4'b0;

        case (opcode)
            // Handle R-type instructions
            7'b0110011: begin
                RegWrite = 1'b1;
                ALUControl = OP_ADD;
            end
        endcase
    end
    
endmodule