module DataMemory (
    input  logic        clk,
    input  logic        MemWrite, // '1' = Write, '0' = Read
    input  logic [31:0] Address,
    input  logic [31:0] WriteData,
    output logic [31:0] ReadData 
);
    
    // 64-word x 32-bit memory array
    logic [31:0] ram_memory [0:63];

    // Synchronous Writes
    always_ff @( posedge clk ) begin
        if (MemWrite) begin
            ram_memory[Address >> 2] <= WriteData; // Shift by 2 to convert the byte address to word index
        end
    end

    // Asynchronous Reads
    assign ReadData = ram_memory[Address >> 2];

endmodule