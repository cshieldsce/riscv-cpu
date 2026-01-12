module HazardUnit (
    // Inputs from ID Stage (Current Instruction)
    input logic [4:0] id_rs1,
    input logic [4:0] id_rs2,

    // Inputs from EX Stage (Previous Instruction)
    input logic [4:0] id_ex_rd,
    input logic id_ex_mem_read, // High if instruction in EX is a load
    
    // Inputs from Branch Logic
    input logic PCSrc,        // High if branch is taken

    // Early jump detection from ID stage
    input logic jump_id_stage,
    
    // Outputs to Control Signals
    output logic stall_if,        // Freeze PC
    output logic stall_id,        // Freeze IF/ID register
    output logic flush_ex,        // Flush ID/EX register (insert NOP)
    output logic flush_id         // Flush IF/ID register
);

    always_comb begin : HazardUnit
        // Default values (no hazards)
        stall_if = 0;
        stall_id = 0;
        flush_ex = 0;
        flush_id = 0;

        // --- LOAD-USE HAZARD DETECTION ---
        // If the instruction in EX is a Load (reading from memory)
        // AND it writes to a register that the current instruction in ID needs.
        if (id_ex_mem_read && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
            stall_if = 1;   // Freeze PC
            stall_id = 1;   // Freeze IF/ID register
            flush_ex = 1;   // Insert NOP in EX stage
        end
        
        // --- CONTROL HAZARD DETECTION ---
        // When PCSrc goes high, a branch/jump in EX stage has been taken.
        // At this moment in the pipeline:
        //   - IF/ID: Contains instruction from wrong path (fetched from PC+4 of branch)
        //   - ID/EX: Contains the branch/jump itself OR instruction before it
        //   - EX/MEM and beyond: Instructions that should complete
        //
        // We only flush IF/ID to kill the speculatively fetched instruction.
        // We do NOT flush ID/EX because it may contain instructions that must complete.
        else if (PCSrc) begin
            flush_id = 1;   // Kill instruction in IF/ID (speculative fetch)
            flush_ex = 1;
        end
        
        // Early jump detected in ID stage - only flush IF/ID
        else if (jump_id_stage) begin
            flush_id = 1;  // Kill the instruction just fetched
        end
    end
endmodule