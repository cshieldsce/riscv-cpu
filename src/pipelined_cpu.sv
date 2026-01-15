// 5-Stage Pipelined RISC-V CPU Top-Level
import riscv_pkg::*;

module PipelinedCPU (
    input  logic             clk,
    input  logic             rst,
    
    // Instruction memory interface
    output logic [ALEN-1:0]  imem_addr,
    input  logic [31:0]      imem_data,
    
    // Data memory interface
    output logic [ALEN-1:0]  dmem_addr,
    input  logic [XLEN-1:0]  dmem_rdata,
    output logic [XLEN-1:0]  dmem_wdata,
    output logic             dmem_we,
    output logic [3:0]       dmem_be,
    output logic [2:0]       dmem_funct3,
    
    output logic [3:0]       leds_out
);

    // ========================================================================
    // PIPELINE REGISTER WIDTHS
    // ========================================================================
    // IF/ID: PC(XLEN) + Inst(32) + PC+4(XLEN)
    localparam IF_ID_WIDTH = XLEN + 32 + XLEN;
    
    // ID/EX: 
    // Data: PC(X), PC+4(X), RD1(X), RD2(X), Imm(X), rs1(5), rs2(5), rd(5), funct3(3)
    // Control: RegWrite(1), MemWrite(1), ALUControl(4), ALUSrc(1), ALUSrcA(2), MemToReg(2), Branch(1), Jump(1), Jalr(1)
    // Total Data: 5*XLEN + 18
    // Total Control: 14
    localparam ID_EX_WIDTH = (5 * XLEN) + 18 + 14;

    // EX/MEM:
    // Data: ALUResult(X), WriteData(X), rd(5), PC+4(X), funct3(3)
    // Control: RegWrite(1), MemWrite(1), MemToReg(2)
    // Total Data: 3*XLEN + 8
    // Total Control: 4
    localparam EX_MEM_WIDTH = (3 * XLEN) + 8 + 4;

    // MEM/WB:
    // Data: ReadData(X), ALUResult(X), rd(5), PC+4(X)
    // Control: RegWrite(1), MemToReg(2)
    // Total Data: 3*XLEN + 5
    // Total Control: 3
    localparam MEM_WB_WIDTH = (3 * XLEN) + 5 + 3;

    localparam PC_MASK_WIDTH = XLEN - 1;
    localparam INSTR_PAD_WIDTH = XLEN - 32;

    // ========================================================================
    // STAGES CONTROL SIGNALS AND WIRES
    // ========================================================================
    
    // --- IF: INSTRUCTION FETCH ---
    logic [XLEN-1:0] if_pc, if_instruction_wire, if_pc_plus_4;
    logic [31:0]     if_instruction; // Instruction is always 32-bit

    // IF/ID PIPELINE REGISTER
    logic [XLEN-1:0] if_id_pc, if_id_pc_plus_4;
    logic [31:0]     if_id_instruction;

    // --- ID: INSTRUCTION DECODE ---
    logic [XLEN-1:0] id_read_data1, id_read_data2, id_imm_out;
    logic [4:0]      id_rs1, id_rs2, id_rd;
    opcode_t         id_opcode;
    logic [2:0]      id_funct3;
    logic [6:0]      id_funct7;

    // ID Control Signals
    logic            id_reg_write, id_mem_write;
    alu_op_t         id_alu_control;
    logic            id_alu_src;
    logic [1:0]      id_alu_src_a;
    logic [1:0]      id_mem_to_reg;
    logic            id_branch, id_jump, id_jalr;

    // ID/EX PIPELINE REGISTER
    logic [XLEN-1:0] id_ex_pc, id_ex_pc_plus_4;
    logic [XLEN-1:0] id_ex_read_data1, id_ex_read_data2, id_ex_imm;
    logic [4:0]      id_ex_rs1, id_ex_rs2, id_ex_rd;

    // ID/EX Control Signals
    logic            id_ex_reg_write, id_ex_mem_write;
    alu_op_t         id_ex_alu_control;
    logic            id_ex_alu_src;
    logic [1:0]      id_ex_alu_src_a;
    logic [1:0]      id_ex_mem_to_reg;
    logic            id_ex_branch, id_ex_jump, id_ex_jalr;

    // --- EX: EXECUTE ---
    logic [XLEN-1:0] ex_alu_result, ex_alu_b_input; 
    logic            ex_zero;
    logic [XLEN-1:0] ex_branch_target;

    // EX/MEM PIPELINE REGISTER
    logic [XLEN-1:0] ex_mem_alu_result, ex_mem_write_data; 
    logic [4:0]      ex_mem_rd;
    logic [XLEN-1:0] ex_mem_pc_plus_4;

    // EX/MEM Control Signals
    logic            ex_mem_reg_write, ex_mem_mem_write;
    logic [1:0]      ex_mem_mem_to_reg;

    // --- MEM: MEMORY ---
    logic [XLEN-1:0] mem_read_data;

    // MEM/WB PIPELINE REGISTER
    logic [XLEN-1:0] mem_wb_read_data, mem_wb_alu_result;
    logic [4:0]      mem_wb_rd;
    logic [XLEN-1:0] mem_wb_pc_plus_4;

    // MEM/WB Control Signals
    logic            mem_wb_reg_write;
    logic [1:0]      mem_wb_mem_to_reg;

    // --- WB: WRITEBACK ---
    logic [XLEN-1:0] wb_write_data; 

    // FORWARDING UNIT
    logic [1:0]      forward_a, forward_b; 
    logic [XLEN-1:0] alu_in_a, alu_in_b;   
    logic [XLEN-1:0] alu_in_a_forwarded;   

    // HAZARD UNIT
    logic stall_if, stall_id, flush_ex, flush_id;
    logic pcsrc; 

    // MMIO signals
    logic [2:0] id_ex_funct3;  
    logic [2:0] ex_mem_funct3; 

    // ========================================================================
    // IF: INSTRUCTION FETCH
    // ========================================================================    

    logic [XLEN-1:0] next_pc; 

    // Early jump detection in ID stage (ONLY for JAL, NOT JALR)
    logic jump_id_stage;
    assign jump_id_stage = id_jump; 
    
    // Combine branch/jalr (from EX)
    assign pcsrc = branch_taken | id_ex_jalr;

    // Calculate JAL target early
    logic [XLEN-1:0] jump_target_id;
    assign jump_target_id = if_id_pc + id_imm_out;

    logic [XLEN-1:0] jalr_masked_pc;
    assign jalr_masked_pc = ex_alu_result & {{ (PC_MASK_WIDTH){1'b1} }, 1'b0};

    always_comb begin
        if (stall_if) begin
            next_pc = if_pc;
        end else if (id_ex_jalr) begin
            // JALR (Resolved in EX stage) - Clear LSB
            next_pc = jalr_masked_pc; 
        end else if (branch_taken) begin
            // Conditional Branch (Resolved in EX stage)
            next_pc = ex_branch_target;
        end else if (id_jump) begin
            // JAL (Resolved in ID stage)
            next_pc = jump_target_id;
        end else begin
            // Normal execution
            next_pc = if_pc_plus_4;
        end
    end

    logic [XLEN-1:0] instruction_in_padded;
    assign instruction_in_padded = {{ (INSTR_PAD_WIDTH){1'b0} }, imem_data};

    // --- IF_Stage ---
    IF_Stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .next_pc_in(next_pc),
        .instruction_in(instruction_in_padded),
        .instruction_out(if_instruction_wire),
        .pc_out(if_pc),
        .pc_plus_4_out(if_pc_plus_4)
    );
    
    assign if_instruction = if_instruction_wire[31:0];
    assign imem_addr = if_pc;

    // IF/ID PIPELINE REGISTER
    PipelineRegister #(IF_ID_WIDTH) if_id_reg (
        .clk(clk),
        .rst(rst),
        .en(~stall_id),
        .clear(flush_id),
        .in({if_pc, if_instruction, if_pc_plus_4}),
        .out({if_id_pc, if_id_instruction, if_id_pc_plus_4}) 
    );

    // ========================================================================
    // ID: INSTRUCTION DECODE
    // ========================================================================

    ID_Stage id_stage_inst (
        .clk(clk),
        .rst(rst),
        .instruction(if_id_instruction),
        .pc(if_id_pc),
        .reg_write_wb(mem_wb_reg_write),
        .write_data_wb(wb_write_data),
        .rd_wb(mem_wb_rd),
        .read_data1(id_read_data1),
        .read_data2(id_read_data2),
        .imm_out(id_imm_out),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .reg_write(id_reg_write),
        .mem_write(id_mem_write),
        .alu_control(id_alu_control),
        .alu_src(id_alu_src),
        .alu_src_a(id_alu_src_a),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr)
    );

    // --- Hazard Unit ---
    HazardUnit hazard_unit_inst (
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_to_reg[0]), 
        .PCSrc(pcsrc),
        .jump_id_stage(jump_id_stage),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .flush_ex(flush_ex),
        .flush_id(flush_id)
    );

    // ID/EX PIPELINE REGISTER
    PipelineRegister #(ID_EX_WIDTH) id_ex_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),        
        .clear(flush_ex), 
        .in({
            // Data Payload
            if_id_pc, if_id_pc_plus_4,
            id_read_data1, id_read_data2, id_imm_out, 
            id_rs1, id_rs2, id_rd, id_funct3,
            // Control Payload
            id_reg_write, id_mem_write,
            id_alu_control, id_alu_src, id_alu_src_a, id_mem_to_reg, 
            id_branch, id_jump, id_jalr
        }),
        .out({
            // Data Payload
            id_ex_pc, id_ex_pc_plus_4, 
            id_ex_read_data1, id_ex_read_data2, id_ex_imm, 
            id_ex_rs1, id_ex_rs2, id_ex_rd, id_ex_funct3,
            // Control Payload
            id_ex_reg_write, id_ex_mem_write,
            id_ex_alu_control, id_ex_alu_src, id_ex_alu_src_a, id_ex_mem_to_reg, 
            id_ex_branch, id_ex_jump, id_ex_jalr
        })
    );

    // ========================================================================
    // EX: EXECUTE
    // ========================================================================

    // --- Forwarding Unit ---
    ForwardingUnit forwarding_unit_inst (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    EX_Stage ex_stage_inst (
        .pc(id_ex_pc),
        .imm(id_ex_imm),
        .rs1_data(id_ex_read_data1),
        .rs2_data(id_ex_read_data2),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .ex_mem_alu_result(ex_mem_alu_result),
        .wb_write_data(wb_write_data),
        .alu_control(id_ex_alu_control),
        .alu_src(id_ex_alu_src),
        .alu_src_a(id_ex_alu_src_a),
        .branch_en(id_ex_branch),
        .funct3(id_ex_funct3),
        .alu_result(ex_alu_result),
        .alu_zero(ex_zero),
        .branch_taken(branch_taken),
        .branch_target(ex_branch_target),
        .rs2_data_forwarded(ex_alu_b_input) // Reuse ex_alu_b_input wire for forwarded rs2
    );

    // EX/MEM PIPELINE REGISTER
    PipelineRegister #(EX_MEM_WIDTH) ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),    
        .clear(1'b0), 
        .in({
            // Data Payload
            ex_alu_result,      
            ex_alu_b_input,           
            id_ex_rd,           
            id_ex_pc_plus_4,    
            id_ex_funct3,
            // Control Payload
            id_ex_reg_write, id_ex_mem_write, id_ex_mem_to_reg
        }),
        .out({
            // Data Payload
            ex_mem_alu_result, ex_mem_write_data, ex_mem_rd, ex_mem_pc_plus_4, ex_mem_funct3,
            // Control Payload
            ex_mem_reg_write, ex_mem_mem_write, ex_mem_mem_to_reg
        })
    );

    // ========================================================================
    // MEM: Memory
    // ========================================================================

    assign dmem_addr = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_write_data;
    assign dmem_we = ex_mem_mem_write;
    assign dmem_funct3 = ex_mem_funct3;
    
    MEM_Stage mem_stage_inst (
        .clk(clk),
        .rst(rst),
        .alu_result(ex_mem_alu_result),
        .write_data(ex_mem_write_data),
        .mem_write_en(ex_mem_mem_write),
        .funct3(ex_mem_funct3),
        .dmem_be(dmem_be),
        .leds_out(leds_out)
    );
    
    assign mem_read_data = dmem_rdata;
    
    // MEM/WB PIPELINE REGISTER
    PipelineRegister #(MEM_WB_WIDTH) mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),    
        .clear(1'b0), 
        .in({
            // Data Payload
            mem_read_data,      
            ex_mem_alu_result,  
            ex_mem_rd,          
            ex_mem_pc_plus_4,   
            // Control Payload
            ex_mem_reg_write, ex_mem_mem_to_reg
        }),
        .out({
            // Data Payload
            mem_wb_read_data, mem_wb_alu_result, mem_wb_rd, mem_wb_pc_plus_4,
            // Control Payload
            mem_wb_reg_write, mem_wb_mem_to_reg
        })
    );

    // ========================================================================
    // WB: Write Back
    // ========================================================================

    // --- Write Back MUX ---
    always_comb begin
        case (mem_wb_mem_to_reg)
            2'b00: wb_write_data = mem_wb_alu_result; 
            2'b01: wb_write_data = mem_wb_read_data;  
            2'b10: wb_write_data = mem_wb_pc_plus_4;  
            default: wb_write_data = {XLEN{1'b0}};
        endcase
    end
endmodule