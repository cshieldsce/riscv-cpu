module HazardUnit (
    // Inputs from ID Stage (Current Instruction)
    input logic [4:0] id_rs1,
    input logic [4:0] id_rs2,

    // Inputs from EX Stage (Previous Instruction)
    input logic [4:0] id_ex_rd,
    input logic id_ex_mem_read, // High if instruction in EX is a load
    
    // Inputs from Branch Logic
    input logic PCSrc,        // High if branch is taken

    // Outputs to Control Signals
    output logic stall_if,        // Freeze PC
    output logic stall_id,        // Freeze IF/ID register
    output logic flush_ex,         // Flush EX/MEM register (insert NOP)
    output logic flush_id        // Flush ID/EX register
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
        if (id_ex_mem_read && ((id_ex_rd == id_rs1 || (id_ex_rd == id_rs2)))) begin
            stall_if = 1;   // Freeze PC
            stall_id = 1;   // Freeze IF/ID register
            flush_ex = 1;   // Insert NOP in EX stage
        end

        // --- CONTROL HAZARD DETECTION ---
        // If a branch or jump is taken, the instructions in IF and ID are from the wrong path.        
        if (PCSrc) begin
            flush_id = 1;   // Kill the instruction in Fetch/Decode register
            flush_ex = 1;   // Kill the instruction in Decode/Execute register
        end
    end
endmodule