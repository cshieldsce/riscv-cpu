import riscv_pkg::*;

module HazardUnit (
    // Inputs from ID Stage (Current Instruction)
    input  logic [4:0] id_rs1,
    input  logic [4:0] id_rs2,

    // Inputs from EX Stage (Previous Instruction)
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_read, // High if instruction in EX is a load
    
    // Inputs from Branch Logic
    input  logic       PCSrc,        // High if branch is taken
    
    // Early jump detection from ID stage
    input  logic       jump_id_stage,
    
    // Outputs to Control Signals
    output logic       stall_if,        // Freeze PC
    output logic       stall_id,        // Freeze IF/ID register
    output logic       flush_ex,        // Flush ID/EX register (insert NOP)
    output logic       flush_id         // Flush IF/ID register
);

    always_comb begin : HazardUnit
        // Default values (no hazards)
        stall_if = 0;
        stall_id = 0;
        flush_ex = 0;
        flush_id = 0;

        // ========================================================================
        // 1. LOAD-USE HAZARD DETECTION
        // ========================================================================
        // Situation:
        //   Instruction in EX is a Load (e.g., lw x1, 0(x2)).
        //   Instruction in ID needs the result (e.g., add x3, x1, x4).
        //
        // Action:
        //   We must stall the pipeline for 1 cycle because the load data
        //   won't be available until the WB stage (forwarding can't help here).
        //
        // Logic:
        //   If (EX.MemRead) AND (EX.rd matches ID.rs1 OR ID.rs2):
        //     - Stall PC (stall_if)
        //     - Stall IF/ID (stall_id)
        //     - Flush ID/EX (flush_ex) -> Inject NOP into EX stage
        //
        if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
            stall_if = 1; 
            stall_id = 1;
            flush_ex = 1;
        end
        
        // ========================================================================
        // 2. CONTROL HAZARD DETECTION
        // ========================================================================
        
        // --- Case A: Branch/JALR Taken (Resolved in EX Stage) ---
        // Situation:
        //   A Branch or JALR instruction in EX stage evaluates to TAKEN.
        //   The pipeline has already fetched instructions from the fall-through path
        //   into the ID and IF stages. These are WRONG path instructions.
        //
        // Action:
        //   Flush BOTH the IF/ID and ID/EX registers.
        //   - flush_id: Kills the instruction currently leaving IF (entering ID).
        //   - flush_ex: Kills the instruction currently leaving ID (entering EX).
        //
        else if (PCSrc) begin
            flush_id = 1;
            flush_ex = 1;
        end
        
        // --- Case B: JAL (Resolved in ID Stage) ---
        // Situation:
        //   A JAL instruction is decoded in the ID stage.
        //   We know the target address immediately (PC + Imm).
        //   The pipeline has already fetched the instruction at PC+4 into IF.
        //
        // Action:
        //   Flush ONLY the IF/ID register.
        //   - flush_id: Kills the instruction at PC+4 (wrong path).
        //   - The JAL instruction itself proceeds to EX validly.
        //
        else if (jump_id_stage) begin
            flush_id = 1;
        end
    end
endmodule