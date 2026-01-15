import riscv_pkg::*;

module EX_Stage (
    // Data Inputs
    input  logic [XLEN-1:0] pc,
    input  logic [XLEN-1:0] imm,
    input  logic [XLEN-1:0] rs1_data,
    input  logic [XLEN-1:0] rs2_data,
    
    // Forwarding Inputs
    input  logic [1:0]      forward_a,
    input  logic [1:0]      forward_b,
    input  logic [XLEN-1:0] ex_mem_alu_result,
    input  logic [XLEN-1:0] wb_write_data,
    
    // Control Inputs
    input  alu_op_t         alu_control,
    input  logic            alu_src,   // 0: register, 1: immediate
    input  logic [1:0]      alu_src_a, // 0: register, 1: PC, 2: Zero
    input  logic            branch_en,
    input  logic [2:0]      funct3,
    
    // Outputs
    output logic [XLEN-1:0] alu_result,
    output logic            alu_zero,
    output logic            branch_taken,
    output logic [XLEN-1:0] branch_target,
    output logic [XLEN-1:0] rs2_data_forwarded // Value to be stored in memory
);

    logic [XLEN-1:0] alu_in_a_forwarded;
    logic [XLEN-1:0] alu_in_a;
    logic [XLEN-1:0] alu_in_b;
    logic [XLEN-1:0] alu_b_final;

    // --- 1. ALU Input A MUX (Forwarding) ---
    always_comb begin
        case (forward_a)
            2'b00:   alu_in_a_forwarded = rs1_data;
            2'b10:   alu_in_a_forwarded = ex_mem_alu_result;
            2'b01:   alu_in_a_forwarded = wb_write_data;
            default: alu_in_a_forwarded = rs1_data;
        endcase
    end

    // --- 2. Handle LUI/AUIPC MUX ---
    always_comb begin
        case (alu_src_a)
            2'b00:   alu_in_a = alu_in_a_forwarded;
            2'b01:   alu_in_a = pc;
            2'b10:   alu_in_a = {XLEN{1'b0}};
            default: alu_in_a = alu_in_a_forwarded;
        endcase
    end

    // --- 3. ALU Input B MUX (Forwarding) ---
    always_comb begin
        case (forward_b)
            2'b00:   alu_in_b = rs2_data;
            2'b10:   alu_in_b = ex_mem_alu_result;
            2'b01:   alu_in_b = wb_write_data;
            default: alu_in_b = rs2_data;
        endcase
    end
    
    // rs2_data_forwarded is needed for the Memory stage (Store data)
    assign rs2_data_forwarded = alu_in_b;

    // --- 4. ALU Source MUX (Immediate vs Register) ---
    assign alu_b_final = (alu_src == 1'b0) ? alu_in_b : imm;

    // --- 5. ALU Instantiation ---
    ALU alu_inst (
        .A(alu_in_a),
        .B(alu_b_final),
        .ALUControl(alu_control),
        .Result(alu_result),
        .Zero(alu_zero)
    );

    // --- 6. Branch Comparison Logic ---
    logic alu_lsb;
    assign alu_lsb = alu_result[0];

    always_comb begin
        branch_taken = 1'b0;
        if (branch_en) begin
            case (funct3)
                F3_BEQ:  branch_taken = alu_zero;
                F3_BNE:  branch_taken = ~alu_zero;
                F3_BLT:  branch_taken = alu_lsb;
                F3_BGE:  branch_taken = ~alu_lsb;
                F3_BLTU: branch_taken = alu_lsb;
                F3_BGEU: branch_taken = ~alu_lsb;
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // --- 7. Branch Target Adder ---
    assign branch_target = pc + imm;

endmodule