module uart_echo (
    input  wire clk,      // 100 MHz clock
    input  wire uart_rx,  // USB-UART RX
    output wire uart_tx   // USB-UART TX
);
    reg [7:0] rx_byte = 0;
    wire      rx_dv;
    
    // Simple loopback assignment for testing
    assign uart_tx = uart_rx; 

endmodule
