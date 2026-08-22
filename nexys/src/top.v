module top (
    input  wire clk,   // oscillator
    input  wire btn,   // Reset (Active Low)
    input  wire RsRx,  // FPGA RX pin
    output wire RsTx   // FPGA TX pin
);

    // 100,000,000 / 115200 = ~868.05
    localparam CLK_PER_BIT = 868;

    // Internal data signals
    wire [7:0] rx_data;
    wire       rx_ready;
    wire       tx_busy;

    // Instantiate UART Receiver
    uart_rx #(.CLK_PER_BIT(CLK_PER_BIT)) rx_inst (
        .clk(clk),
        .arstn(!btn),
        .rx(RsRx),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );

    // Instantiate UART Transmitter
    uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) tx_inst (
        .clk(clk),
        .arstn(!btn),
        .tx_start(rx_ready && !tx_busy), // Trigger send when byte is received
        .tx_data(rx_data),
        .tx(RsTx),
        .tx_busy(tx_busy)
    );

endmodule
