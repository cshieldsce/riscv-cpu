import riscv_pkg::*;

module ForwardingUnit (
    input  logic [4:0] id_ex_rs1,   // Source 1 from ID/EX register
    input  logic [4:0] id_ex_rs2,   // Source 2 from ID/EX register
    
    // Data from MEM stage (the next instruction)
    input  logic [4:0] ex_mem_rd,      
    input  logic       ex_mem_reg_write,
    
    // Data from WB stage (the instruction 2 cycles ahead)
    input  logic [4:0] mem_wb_rd,      
    input  logic       mem_wb_reg_write,
    
    output logic [1:0] forward_a,  // MUX selector for ALU Input A
    output logic [1:0] forward_b   // MUX selector for ALU Input B
);

    /*
      FORWARDING PATHS DIAGRAM
      ========================

      Instruction Sequence:
      1. ADD x1, x2, x3   (in WB stage)  -> Writes to x1
      2. SUB x4, x1, x5   (in MEM stage) -> Reads x1 (Data Hazard!)
      3. AND x6, x1, x7   (in EX stage)  -> Reads x1 (Data Hazard!)

      Pipeline Stages:
      [ WB ] <-------+
                     | Forward from WB (MEM Hazard)
      [ MEM] <----+  |
                  |  |
                  |  | Forward from EX (EX Hazard)
                  |  |
      [ EX ] -----+--+---> ALU Inputs

      MUX Selectors:
      00: No forwarding (Use value from ID/EX register)
      10: Forward from EX/MEM stage (Most recent result)
      01: Forward from MEM/WB stage (Older result)
    */

    always_comb begin
        forward_a = 2'b00; // Default: No forwarding
        forward_b = 2'b00;

        // ====================================================================
        // 1. EX HAZARD (Forwarding from EX/MEM stage)
        // ====================================================================
        // If the previous instruction (now in MEM) writes to the register
        // we are currently reading (in EX), forward the result immediately.
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end

        // ====================================================================
        // 2. MEM HAZARD (Forwarding from MEM/WB stage)
        // ====================================================================
        // If the instruction 2 cycles ago (now in WB) writes to the register
        // we are reading, forward it.
        //
        // CRITICAL: We only forward from WB if there is NOT a more recent 
        // match in the EX stage (Double Hazard). The EX stage result is newer.
        
        if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1) && 
            !(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))) begin
            forward_a = 2'b01;
        end
        
        if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2) && 
            !(ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))) begin
            forward_b = 2'b01;
        end
    end

endmodule