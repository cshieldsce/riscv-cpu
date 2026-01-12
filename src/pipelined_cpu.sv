// 5-Stage Pipelined RISC-V CPU Top-Level
import riscv_pkg::*;
module PipelinedCPU (
    input logic clk,
    input logic rst,
    
    // Instruction memory interface
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_data,
    
    // Data memory interface
    output logic [31:0] dmem_addr,
    input  logic [31:0] dmem_rdata,
    output logic [31:0] dmem_wdata,
    output logic        dmem_we,
    output logic [3:0]  dmem_be,
    
    output logic [3:0] leds_out
);
    // ========================================================================
    // STAGES CONTROL SIGNALS AND WIRES
    // ========================================================================
    
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
    logic [1:0]  id_alu_src_a;
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
    logic [1:0]  id_ex_alu_src_a;
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

    // FORWARDING UNIT
    logic [1:0]  forward_a, forward_b; // MUX selectors from ForwardingUnit
    logic [31:0] alu_in_a, alu_in_b;   // The actual data entering the ALU
    logic [31:0] alu_in_a_forwarded;   // Intermediate wire for MUX

    // HAZARD UNIT
    logic stall_if, stall_id, flush_ex, flush_id;
    logic pcsrc; // Combined branch/jump signal

    // MMIO signals
    logic [2:0] id_ex_funct3;  // Funct3 in Execute Stage
    logic [2:0] ex_mem_funct3; // Funct3 in Memory Stage

    // ========================================================================
    // IF: INSTRUCTION FETCH
    // ========================================================================    

    logic [31:0] next_pc; // Wire for the next PC address

    // --- Branch Decision Logic ---
    logic alu_lsb;
    assign alu_lsb = ex_alu_result[0];
    logic branch_taken;

    always @(*) begin
        branch_taken = 1'b0;
        
        if (id_ex_branch) begin
            case (id_ex_funct3)
                F3_BEQ:  branch_taken = ex_zero;
                F3_BNE:  branch_taken = ~ex_zero;
                F3_BLT:  branch_taken = alu_lsb;
                F3_BGE:  branch_taken = ~alu_lsb;
                F3_BLTU: branch_taken = alu_lsb;
                F3_BGEU: branch_taken = ~alu_lsb;
                default: branch_taken = 1'b0;
            endcase
        end
    end

    // Early jump detection in ID stage
    logic jump_id_stage;
    assign jump_id_stage = (id_jump | id_jalr);
    
    // Combine branch (from EX) and jump (from ID)
    assign pcsrc = branch_taken | jump_id_stage;

    // Calculate jump target early
    logic [31:0] jump_target_id;
    assign jump_target_id = if_id_pc + id_imm_out;

    always_comb begin
        if (stall_if) begin
            next_pc = if_pc;
        end else if (id_jalr) begin
            // JALR uses register value (but we can't read it yet in ID stage)
            // For now, still wait for EX stage for JALR
            next_pc = ex_alu_result;
        end else if (id_jump) begin
            // JAL can be resolved in ID stage!
            next_pc = jump_target_id;
        end else if (branch_taken) begin
            next_pc = ex_branch_target;
        end else begin
            next_pc = if_pc_plus_4;
        end
    end

    // --- IF_Stage ---
    IF_Stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .next_pc_in(next_pc),
        .instruction_in(imem_data),      // External instruction input
        .instruction_out(if_instruction),
        .pc_out(if_pc),
        .pc_plus_4_out(if_pc_plus_4)
    );
    
    // Expose PC as instruction memory address
    assign imem_addr = if_pc;

    // IF/ID PIPELINE REGISTER:
    // This register saves the state between Fetch and Decode.
    //
    // Total Width Calculation:
    // Data: PC (32) + Instruction (32) + PC+4 (32)
    // Total = 96 bits
    //

    PipelineRegister #(96) if_id_reg (
        .clk(clk),
        .rst(rst),
        .en(~stall_id),                                      // Stall if needed
        .clear(flush_id),                                    // Flush if needed
        .in({if_pc, if_instruction, if_pc_plus_4}),          // Pack inputs
        .out({if_id_pc, if_id_instruction, if_id_pc_plus_4}) // Unpack outputs
    );

    // ========================================================================
    // ID: INSTRUCTION DECODE
    // ========================================================================

    // --- Instruction Decoding ---
    assign id_opcode = if_id_instruction[6:0];
    assign id_rd     = if_id_instruction[11:7];
    assign id_funct3 = if_id_instruction[14:12];
    assign id_rs1    = if_id_instruction[19:15];
    assign id_rs2    = if_id_instruction[24:20];
    assign id_funct7 = if_id_instruction[31:25];

    // --- Control Unit ---
    ControlUnit control_unit_inst (
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .RegWrite(id_reg_write),
        .ALUControl(id_alu_control),
        .ALUSrcA(id_alu_src_a),
        .ALUSrc(id_alu_src),
        .MemWrite(id_mem_write),
        .MemToReg(id_mem_to_reg),
        .Branch(id_branch),
        .Jump(id_jump),
        .Jalr(id_jalr)
    );

    // --- Register File ---
    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(mem_wb_reg_write), // Write comes from the WB stage
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(mem_wb_rd),              // Write address comes from WB stage
        .WriteData(wb_write_data),   // Write data comes from WB stage
        .ReadData1(id_read_data1),
        .ReadData2(id_read_data2)
    );

    // --- Immediate Generator ---
    ImmGen imm_gen_inst (
        .instruction(if_id_instruction),
        .opcode(id_opcode),
        .imm_out(id_imm_out)
    );

    // --- Hazard Unit ---
    HazardUnit hazard_unit_inst (
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_to_reg[0]), // Bit 0 of MemToReg is 1 for LW (01)
        .PCSrc(pcsrc),
        .jump_id_stage(jump_id_stage),
        .stall_if(stall_if),
        .stall_id(stall_id),
        .flush_ex(flush_ex),
        .flush_id(flush_id)
    );

    // ID/EX PIPELINE REGISTER:
    //
    // Total Width Calculation:
    // This register captures all data and control signals needed for the EX stage.
    // Data: PC(32) + PC+4(32) + ReadData1(32) + ReadData2(32) + Imm(32) + rs1(5) + rs2(5) + rd(5) + funct3(3) = 178 bits
    // Control: RegWrite(1) + MemWrite(1) + ALUControl(4) + ALUSrc(1) + ALUSrcA(2) + MemToReg(2) + Branch(1) + Jump(1) + Jalr(1) = 14 bits
    // Total = 192 bits
    //

    PipelineRegister #(192) id_ex_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),        // Always enable ID/EX register
        .clear(flush_ex), // Flush if needed
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

    // --- 1. ALU Input A MUX ---
    always_comb begin
        case (forward_a)
            2'b00: alu_in_a_forwarded = id_ex_read_data1;    // No forwarding (reg file)
            2'b10: alu_in_a_forwarded = ex_mem_alu_result;   // Forward from EX stage
            2'b01: alu_in_a_forwarded = wb_write_data;       // Forward from WB stage
            default: alu_in_a_forwarded = id_ex_read_data1;
        endcase
    end

    // --- 2. Handle LUI/AUIPC Instruction Type MUX --- 
    always_comb begin
        case (id_ex_alu_src_a)
            2'b00: alu_in_a = alu_in_a_forwarded;       // Normal (Register/Forwarded)
            2'b01: alu_in_a = id_ex_pc;                 // PC (for AUIPC)
            2'b10: alu_in_a = 32'd0;                    // Zero (for LUI)
            default: alu_in_a = alu_in_a_forwarded;
        endcase
    end

    // --- 3. ALU Input B MUX ---
    always_comb begin
        case (forward_b)
            2'b00: alu_in_b = id_ex_read_data2;       // No forwarding (reg file)
            2'b10: alu_in_b = ex_mem_alu_result;      // Forward from EX stage
            2'b01: alu_in_b = wb_write_data;          // Forward from WB stage
            default: alu_in_b = id_ex_read_data2;
        endcase
    end

    // --- 4. ALU Source MUX (Immediate vs Register) ---
    // Uses 'alu_in_b' (the forwarded value) instead of 'id_ex_read_data2'
    assign ex_alu_b_input = (id_ex_alu_src == 1'b0) ? alu_in_b : id_ex_imm;

    // --- ALU Instantiation ---
    ALU alu_inst (
        .A(alu_in_a),              // Use new MUX output
        .B(ex_alu_b_input),        // Use existing MUX output
        .ALUControl(id_ex_alu_control),
        .Result(ex_alu_result),
        .Zero(ex_zero)
    );

    // We calculate the branch target every cycle, just in case it's a branch.
    assign ex_branch_target = id_ex_pc + id_ex_imm;

    // EX/MEM PIPELINE REGISTER:
    // This register captures the calculation results for the Memory stage.
    //
    // Total Width Calculation:
    // Data: ALUResult(32) + WriteData(32, from rs2) + rd(5) + PC+4(32) + funct3(3) = 104 bits
    // Control: RegWrite(1) + MemWrite(1) + MemToReg(2) = 4 bits
    // Total = 108 bits
    //

    PipelineRegister #(108) ex_mem_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),    // Always enable
        .clear(1'b0), // No flush
        .in({
            // Data Payload
            ex_alu_result,      // The address (for L/S) or math result
            alu_in_b,           // The data to write to memory (for SW)
            id_ex_rd,           // The destination register address
            id_ex_pc_plus_4,    // For JAL/JALR linking
            // Control Payload
            id_ex_reg_write, id_ex_mem_write, id_ex_mem_to_reg, id_ex_funct3
        }),
        .out({
            // Data Payload
            ex_mem_alu_result, ex_mem_write_data, ex_mem_rd, ex_mem_pc_plus_4,
            // Control Payload
            ex_mem_reg_write, ex_mem_mem_write, ex_mem_mem_to_reg, ex_mem_funct3
        })
    );

    // ========================================================================
    // MEM: Memory
    // ========================================================================

    // Expose data memory interface
    assign dmem_addr = ex_mem_alu_result;
    assign dmem_wdata = ex_mem_write_data;
    assign dmem_we = ex_mem_mem_write;
    
    // Generate byte enables based on funct3
    always_comb begin
        case (ex_mem_funct3)
            3'b000, 3'b100: begin  // LB/LBU/SB
                case (dmem_addr[1:0])
                    2'b00: dmem_be = 4'b0001;
                    2'b01: dmem_be = 4'b0010;
                    2'b10: dmem_be = 4'b0100;
                    2'b11: dmem_be = 4'b1000;
                endcase
            end
            3'b001, 3'b101: begin  // LH/LHU/SH
                dmem_be = dmem_addr[1] ? 4'b1100 : 4'b0011;
            end
            default: dmem_be = 4'b1111;  // LW/SW
        endcase
    end
    
    // Connect external memory read data to pipeline
    assign mem_read_data = dmem_rdata;
    
    // MMIO - Extract LED output from memory writes
    always_ff @(posedge clk) begin
        if (rst) begin
            leds_out <= 4'b0;
        end else if (dmem_we && dmem_addr == 32'hFFFF_FFF0) begin
            // LED address - capture write data
            leds_out <= dmem_wdata[3:0];
        end
    end

    // MEM/WB PIPELINE REGISTER:
    // This register saves the final results for the Writeback stage.
    //
    // Total Width Calculation:
    // Data: ReadData(32) + ALUResult(32) + rd(5) + PC+4(32) = 101 bits
    // Control: RegWrite(1) + MemToReg(2) = 3 bits
    // Total = 104 bits
    //

    PipelineRegister #(104) mem_wb_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),    // Always enable
        .clear(1'b0), // No flush
        .in({
            // Data Payload
            mem_read_data,      // Data read from memory
            ex_mem_alu_result,  // ALU Result (pass through)
            ex_mem_rd,          // Destination Register
            ex_mem_pc_plus_4,   // PC+4 (for JAL/JALR)
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
    // Selects the final value to write back to the register file.
    always_comb begin
        case (mem_wb_mem_to_reg)
            2'b00: wb_write_data = mem_wb_alu_result; // R-type, I-type
            2'b01: wb_write_data = mem_wb_read_data;  // Load (lw)
            2'b10: wb_write_data = mem_wb_pc_plus_4;  // Jal/Jalr
            default: wb_write_data = 32'b0;
        endcase
    end
endmodule