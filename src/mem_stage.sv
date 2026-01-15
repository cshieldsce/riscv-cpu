import riscv_pkg::*;

module MEM_Stage (
    input  logic             clk,
    input  logic             rst,
    
    // Inputs from EX stage (via EX/MEM register)
    input  logic [XLEN-1:0]  alu_result,
    input  logic [XLEN-1:0]  write_data,
    input  logic             mem_write_en,
    input  logic [2:0]       funct3,
    
    // Memory Interface Outputs
    output logic [3:0]       dmem_be,
    
    // MMIO Outputs
    output logic [3:0]       leds_out
);

    // --- 1. Byte Enable Generation ---
    logic [3:0] be_byte, be_half;

    assign be_byte = (alu_result[1:0] == 2'b00) ? 4'b0001 :
                     (alu_result[1:0] == 2'b01) ? 4'b0010 :
                     (alu_result[1:0] == 2'b10) ? 4'b0100 :
                     (alu_result[1:0] == 2'b11) ? 4'b1000 : 4'b1111;

    assign be_half = alu_result[1] ? 4'b1100 : 4'b0011;

    always_comb begin
        case (funct3)
            F3_BYTE, F3_LBU: dmem_be = be_byte;
            F3_HALF, F3_LHU: dmem_be = be_half;
            default:         dmem_be = 4'b1111;  
        endcase
    end

    // --- 2. MMIO - LED Logic ---
    always_ff @(posedge clk) begin
        if (rst) begin
            leds_out <= 4'b0;
        end else if (mem_write_en && alu_result == MMIO_LED_ADDR) begin
            // LED address - capture write data
            leds_out <= write_data[3:0];
        end
    end

endmodule