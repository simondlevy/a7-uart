module uart_echo (
    input clk,          // 12MHz clock on Cmod A7 typically, or scaled
    input RsRx,         // Pin mapped to USB-UART RX
    output RsTx         // Pin mapped to USB-UART TX
);
    // Wire up internal RX data and valid signals from a standard UART RX/TX core
    wire [7:0] rx_byte;
    wire rx_dv;

    // 12MHz / 115200 baud = 104 cycles per bit
    
    uart_rx #(.CLKS_PER_BIT(104)) UART_RX_Inst (
        .i_Clock(clk),
        .i_Rx_Serial(RsRx),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );

    uart_tx #(.CLKS_PER_BIT(104)) UART_TX_Inst (
        .i_Clock(clk),
        .i_Tx_DV(rx_dv),       // Echo back immediately when data is valid
        .i_Tx_Byte(rx_byte),
        .o_Tx_Serial(RsTx),
        .o_Tx_Done()
    );
endmodule
