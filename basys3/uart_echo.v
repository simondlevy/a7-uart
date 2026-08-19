module uart_echo (
    input  wire clk,      // 12 MHz clock on Cmod A7
    input  wire uart_rx,  // USB-UART RX
    output wire uart_tx   // USB-UART TX
);
    // 100MHz / 115200 baud = 868 cycles per bit
    parameter CLKS_PER_BIT = 868; 

    reg [7:0] rx_byte = 0;
    wire      rx_dv;
    
    // Simple loopback assignment for testing
    assign uart_tx = uart_rx; 

endmodule
