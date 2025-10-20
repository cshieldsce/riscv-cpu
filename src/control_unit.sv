module ControlUnit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic RegWrite,
    output logic [3:0] ALUControl
);

    parameter OP_ADD = 4'b0010;
    parameter OP_SUB = 4'b0110;
    always_comb begin
        // Set controls to an idle state (0)
        RegWrite = 1'b0;
        ALUControl = 4'b0000;

        // Since the opcode is shared we check funct3 and funct7 to determine the specific operation
        case (opcode)
            7'b0110011: begin // Handle R-type instructions
                RegWrite = 1'b1;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: ALUControl = OP_ADD; // add
                    {7'b0100000, 3'b000}: ALUControl = OP_SUB; // sub
                    default: ALUControl = 4'b0000;
                endcase
            end
        endcase
    end

endmodule