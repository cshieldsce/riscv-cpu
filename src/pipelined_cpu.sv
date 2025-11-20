// 5-Stage Pipelined RISC-V CPU Top-Level
module PipelinedCPU (
    input logic clk,
    input logic rst
);

    // --- IF: INSTRUCTION FETCH ---
    logic [31:0] if_pc, if_instruction, if_pc_plus_4;

    // IF/ID PIPELINE REGISTER
    logic [31:0] if_id_pc, if_id_instruction, if_id_pc_plus_4;

    // --- ID: INSTRUCTION DECODE ---
    logic [31:0] id_read_data1, id_read_data2, id_imm_out;
    logic [4:0]  id_rs1, id_rs2, id_rd;
    logic [6:0]  id_opcode;
    logic [2:0]  id_funct3;
    logic [6:0]  id_funct7;

    // ID Control Signals
    logic        id_reg_write, id_mem_write;
    logic [3:0]  id_alu_control;
    logic        id_alu_src;
    logic [1:0]  id_mem_to_reg;
    logic        id_branch, id_jump, id_jalr;

    // ID/EX PIPELINE REGISTER
    logic [31:0] id_ex_pc, id_ex_pc_plus_4;
    logic [31:0] id_ex_read_data1, id_ex_read_data2, id_ex_imm;
    logic [4:0]  id_ex_rs1, id_ex_rs2, id_ex_rd;

    // ID/EX Control Signals
    logic        id_ex_reg_write, id_ex_mem_write;
    logic [3:0]  id_ex_alu_control;
    logic        id_ex_alu_src;
    logic [1:0]  id_ex_mem_to_reg;
    logic        id_ex_branch, id_ex_jump, id_ex_jalr;

    // --- EX: EXECUTE ---
    logic [31:0] ex_alu_result, ex_alu_b_input; // Value after ALUSrc MUX
    logic        ex_zero;
    logic [31:0] ex_branch_target;

    // EX/MEM PIPELINE REGISTER
    logic [31:0] ex_mem_alu_result, ex_mem_write_data; // Data to store to memory (from rs2)
    logic [4:0]  ex_mem_rd;
    logic [31:0] ex_mem_pc_plus_4;

    // EX/MEM Control Signals
    logic        ex_mem_reg_write, ex_mem_mem_write;
    logic [1:0]  ex_mem_mem_to_reg;

    // --- MEM: MEMORY ---
    logic [31:0] mem_read_data;

    // MEM/WB PIPELINE REGISTER
    logic [31:0] mem_wb_read_data, mem_wb_alu_result;
    logic [4:0]  mem_wb_rd;
    logic [31:0] mem_wb_pc_plus_4;

    // MEM/WB Control Signals
    logic        mem_wb_reg_write;
    logic [1:0]  mem_wb_mem_to_reg;

    // --- WB: WRITEBACK ---
    logic [31:0] wb_write_data; // Final data to write back to RegFile

    // PIPELINE STAGE INSTANTIATION
    // ....

endmodule