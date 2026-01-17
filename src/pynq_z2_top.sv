import riscv_pkg::*;

module pynq_z2_top (
    input  logic       sysclk,    // 125MHz from board
    input  logic       reset_btn, // BTN0 (Active High)
    output logic [3:0] led,       // 4 onboard LEDs
    output logic       uart_tx    // PMOD JA1 Pin 1
);

    // --- 1. Clock Management ---
    // Divide 125MHz down to ~7.8MHz (125 / 16) for safety
    // Using a simple counter-based divider
    logic [3:0] clk_div;
    logic       cpu_clk;
    
    always_ff @(posedge sysclk) begin
        clk_div <= clk_div + 1;
    end
    assign cpu_clk = clk_div[3];

    // --- 2. CPU Signals ---
    logic [ALEN-1:0] imem_addr;
    logic [31:0]     imem_data;
    logic            imem_en;
    
    logic [ALEN-1:0] dmem_addr;
    logic [XLEN-1:0] dmem_rdata, dmem_wdata;
    logic dmem_we;
    logic [3:0]      dmem_be;
    logic [2:0]      dmem_funct3;

    // --- 3. CPU Instance ---
    PipelinedCPU cpu_inst (
        .clk(cpu_clk),
        .rst(reset_btn),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_en(imem_en),
        .dmem_addr(dmem_addr),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_be(dmem_be),
        .dmem_funct3(dmem_funct3)
    );

    // --- 4. Instruction Memory ---
    InstructionMemory imem_inst (
        .clk(cpu_clk),
        .en(imem_en),
        .Address(imem_addr),
        .Instruction(imem_data)
    );

    // --- 5. Data Memory ---
    DataMemory dmem_inst (
        .clk(cpu_clk),
        .MemWrite(dmem_we),
        .be(dmem_be),
        .funct3(dmem_funct3),
        .Address(dmem_addr),
        .WriteData(dmem_wdata),
        .ReadData(dmem_rdata),
        .leds_out(led),      // LEDs driven by CPU directly
        .uart_tx_wire(uart_tx)   // UART driven by CPU directly
    );

endmodule
