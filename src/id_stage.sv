import riscv_pkg::*;

module ID_Stage (
    input  logic             clk,
    input  logic             rst,
    
    // Inputs from IF stage (via IF/ID register)
    input  logic [31:0]      instruction,
    input  logic [XLEN-1:0]  pc,
    
    // Inputs from WB stage (Writeback)
    input  logic             reg_write_wb,
    input  logic [XLEN-1:0]  write_data_wb,
    input  logic [4:0]       rd_wb,
    
    // Outputs to ID/EX register and Hazard Unit
    output logic [XLEN-1:0]  read_data1,
    output logic [XLEN-1:0]  read_data2,
    output logic [XLEN-1:0]  imm_out,
    output logic [4:0]       rs1,
    output logic [4:0]       rs2,
    output logic [4:0]       rd,
    output opcode_t          opcode,
    output logic [2:0]       funct3,
    output logic [6:0]       funct7,
    
    // Control Signal Outputs
    output logic             reg_write,
    output logic             mem_write,
    output alu_op_t          alu_control,
    output logic             alu_src,
    output logic [1:0]       alu_src_a,
    output logic [1:0]       mem_to_reg,
    output logic             branch,
    output logic             jump,
    output logic             jalr
);

    // --- Instruction Decoding ---
    assign opcode = opcode_t'(instruction[6:0]);
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

    // --- Control Unit ---
    ControlUnit control_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .RegWrite(reg_write),
        .ALUControl(alu_control),
        .ALUSrcA(alu_src_a),
        .ALUSrc(alu_src),
        .MemWrite(mem_write),
        .MemToReg(mem_to_reg),
        .Branch(branch),
        .Jump(jump),
        .Jalr(jalr)
    );

    // --- Register File ---
    RegFile reg_file_inst (
        .clk(clk),
        .RegWrite(reg_write_wb), 
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd_wb),              
        .WriteData(write_data_wb),   
        .ReadData1(read_data1),
        .ReadData2(read_data2)
    );

    // --- Immediate Generator ---
    ImmGen imm_gen_inst (
        .instruction(instruction),
        .opcode(opcode),
        .imm_out(imm_out)
    );

endmodule