// --- UART TRANSMITTER MODULE ---
module uart_tx #(parameter CLK_PER_BIT = 868) (
    input  wire       clk,
    input  wire       arstn,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy
);
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    reg [1:0]  state     = STATE_IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  tx_shifter= 0;

    always @(posedge clk or negedge arstn) begin
        if (!arstn) begin
            state   <= STATE_IDLE;
            tx      <= 1'b1;
            tx_busy <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        tx_busy    <= 1'b1;
                        tx_shifter <= tx_data;
                        state      <= STATE_START;
                    end
                end
                
                STATE_START: begin
                    tx <= 1'b0; // Start bit
                    if (clk_count < CLK_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= STATE_DATA;
                    end
                end
                
                STATE_DATA: begin
                    tx <= tx_shifter[bit_index];
                    if (clk_count < CLK_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state     <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
                
                STATE_STOP: begin
                    tx <= 1'b1; // Stop bit
                    if (clk_count < CLK_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= STATE_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
