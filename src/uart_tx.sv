module uart_tx #(
    parameter CLKS_PER_BIT = 868 // Defaults to 9600 baud at 100MHz (approx)
)(
    input  logic       clk,
    input  logic       rst,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic       tx_busy,
    output logic       tx_done
);

    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        START_BIT = 3'b001,
        DATA_BITS = 3'b010,
        STOP_BIT  = 3'b011,
        CLEANUP   = 3'b100
    } state_t;

    state_t state;
    
    logic [15:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  data_buffer;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            tx          <= 1'b1; // Idle state is High
            tx_busy     <= 1'b0;
            tx_done     <= 1'b0;
            clk_count   <= 0;
            bit_index   <= 0;
            data_buffer <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx          <= 1'b1;
                    tx_done     <= 1'b0;
                    clk_count   <= 0;
                    bit_index   <= 0;
                    
                    if (tx_start) begin
                        state       <= START_BIT;
                        tx_busy     <= 1'b1;
                        data_buffer <= tx_data;
                    end else begin
                        tx_busy     <= 1'b0;
                    end
                end

                START_BIT: begin
                    tx <= 1'b0; // Start bit is Low
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    tx <= data_buffer[bit_index]; // LSB First
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP_BIT;
                        end
                    end
                end

                STOP_BIT: begin
                    tx <= 1'b1; // Stop bit is High
                    
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= CLEANUP;
                        tx_done   <= 1'b1;
                    end
                end

                CLEANUP: begin
                    // Stay in cleanup for 1 cycle to ensure done signal is seen
                    tx_done <= 1'b1; 
                    state   <= IDLE;
                    tx_busy <= 1'b0;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
