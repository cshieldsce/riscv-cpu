// 5-Stage Pipelined RISC-V CPU Top-Level
module PipelinedCPU (
    input logic clk,
    input logic rst
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

    // Forwarding Wires
    logic [1:0]  forward_a, forward_b; // MUX selectors from ForwardingUnit
    logic [31:0] alu_in_a, alu_in_b;   // The actual data entering the ALU

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

    // ========================================================================
    // IF: INSTRUCTION FETCH
    // ========================================================================    

    logic [31:0] next_pc; // Wire for the next PC address

    // For now, just fetch the next sequential instruction (PC+4).
    // TODO: We will add the MUX here later to handle Branches and Jumps!
    assign next_pc = if_pc_plus_4;

    // --- IF_Stage ---
    IF_Stage if_stage_inst (
        .clk(clk),
        .rst(rst),
        .next_pc_in(next_pc),             // Input: Next PC
        .instruction_out(if_instruction), // Output: Fetched Instruction
        .pc_out(if_pc),                   // Output: Current PC
        .pc_plus_4_out(if_pc_plus_4)      // Output: PC + 4
    );

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
        .en(1'b1),                                           // Always enabled (for now)
        .clear(1'b0),                                        // No flush (for now)
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

    // ID/EX PIPELINE REGISTER:
    //
    // Total Width Calculation:
    // This register captures all data and control signals needed for the EX stage.
    // Data: PC(32) + PC+4(32) + ReadData1(32) + ReadData2(32) + Imm(32) + rs1(5) + rs2(5) + rd(5) = 175 bits
    // Control: RegWrite(1) + MemWrite(1) + ALUControl(4) + ALUSrc(1) + MemToReg(2) + Branch(1) + Jump(1) + Jalr(1) = 12 bits
    // Total = 187 bits
    //

    PipelineRegister #(187) id_ex_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),    // Always enable (for now)
        .clear(1'b0), // No flush (for now)
        .in({
            // Data Payload
            if_id_pc, if_id_pc_plus_4,
            id_read_data1, id_read_data2, id_imm_out, 
            id_rs1, id_rs2, id_rd,
            // Control Payload
            id_reg_write, id_mem_write,
            id_alu_control, id_alu_src, id_mem_to_reg, 
            id_branch, id_jump, id_jalr
        }),
        .out({
            // Data Payload
            id_ex_pc, id_ex_pc_plus_4, 
            id_ex_read_data1, id_ex_read_data2, id_ex_imm, 
            id_ex_rs1, id_ex_rs2, id_ex_rd,
            // Control Payload
            id_ex_reg_write, id_ex_mem_write,
            id_ex_alu_control, id_ex_alu_src, id_ex_mem_to_reg, 
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

    // --- ALU Input A MUX ---
    always_comb begin
        case (forward_a)
            2'b00: alu_in_a = id_ex_read_data1;    // No forwarding (reg file)
            2'b10: alu_in_a = ex_mem_alu_result;   // Forward from EX stage
            2'b01: alu_in_a = wb_write_data;       // Forward from WB stage
            default: alu_in_a = id_ex_read_data1;
        endcase
    end

    // --- ALU Input B MUX ---
    // This determines the value *before* the ALUSrc MUX
    always_comb begin
        case (forward_b)
            2'b00: alu_in_b = id_ex_read_data2;    // No forwarding (reg file)
            2'b10: alu_in_b = ex_mem_alu_result;   // Forward from EX stage
            2'b01: alu_in_b = wb_write_data;       // Forward from WB stage
            default: alu_in_b = id_ex_read_data2;
        endcase
    end

    // --- ALU Source MUX (Immediate vs Register) ---
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
    // Data: ALUResult(32) + WriteData(32, from rs2) + rd(5) + PC+4(32) = 101 bits
    // Control: RegWrite(1) + MemWrite(1) + MemToReg(2) = 4 bits
    // Total = 105 bits
    //

    PipelineRegister #(105) ex_mem_reg (
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
            id_ex_reg_write, id_ex_mem_write, id_ex_mem_to_reg
        }),
        .out({
            // Data Payload
            ex_mem_alu_result, ex_mem_write_data, ex_mem_rd, ex_mem_pc_plus_4,
            // Control Payload
            ex_mem_reg_write, ex_mem_mem_write, ex_mem_mem_to_reg
        })
    );

    // ========================================================================
    // 4. MEM: Memory
    // ========================================================================

    // --- Data Memory ---
    DataMemory data_memory_inst (
        .clk(clk),
        .MemWrite(ex_mem_mem_write),    // Write enable from EX/MEM reg
        .Address(ex_mem_alu_result),    // Address from ALU result
        .WriteData(ex_mem_write_data),  // Data to write (from rs2)
        .ReadData(mem_read_data)        // Output: Data read from memory
    );

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

    // --- WAVEFORM DUMPING ---
    initial begin
        // 1. Create the file "waveform.vcd"
        $dumpfile("waveform.vcd");
        
        // 2. Dump everything (level 0) inside the testbench module
        $dumpvars(0, fib_test_tb);
    end

endmodule