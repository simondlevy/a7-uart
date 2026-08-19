// Top module for Nexys A7 UART Echo at 115200 Baud
// Input Clock: 100 MHz (E3)
module uart_echo (
    input  wire clk,     // 100 MHz oscillator
    input  wire rst_n,   // Reset (Active Low)
    input  wire rx,      // FPGA RX pin (C4)
    output wire tx       // FPGA TX pin (D4)
);

    // Clock division for 115200 baud from 100 MHz
    // 100,000,000 / 115200 = ~868.05
    localparam CLK_PER_BIT = 868;

    // Internal data signals
    wire [7:0] rx_data;
    wire       rx_ready;
    wire       tx_busy;

    // Instantiate UART Receiver
    uart_rx #(.CLK_PER_BIT(CLK_PER_BIT)) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );

    // Instantiate UART Transmitter
    uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(rx_ready && !tx_busy), // Trigger send when byte is received
        .tx_data(rx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

endmodule

// --- UART RECEIVER MODULE ---
module uart_rx #(parameter CLK_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg        rx_ready,
    output reg  [7:0] rx_data
);
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    reg [1:0]  state     = STATE_IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  rx_shifter= 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= STATE_IDLE;
            rx_ready <= 1'b0;
        end else begin
            rx_ready <= 1'b0;
            
            case (state)
                STATE_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx == 1'b0) state <= STATE_START; // Start bit detected
                end
                
                STATE_START: begin
                    if (clk_count == (CLK_PER_BIT / 2) - 1) begin
                        if (rx == 1'b0) begin
                            clk_count <= 0;
                            state     <= STATE_DATA;
                        end else begin
                            state     <= STATE_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                
                STATE_DATA: begin
                    if (clk_count < CLK_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count          <= 0;
                        rx_shifter[bit_index] <= rx;
                        
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state     <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
                
                STATE_STOP: begin
                    if (clk_count < CLK_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        rx_ready  <= 1'b1;
                        rx_data   <= rx_shifter;
                        state     <= STATE_IDLE;
                    end
                end
            endcase
        end
    end
endmodule

// --- UART TRANSMITTER MODULE ---
module uart_tx #(parameter CLK_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst_n,
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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
