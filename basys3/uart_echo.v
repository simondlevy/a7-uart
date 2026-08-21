module uart_echo (
    input  wire clk,      // 100 MHz clock
    input  wire RsRx,  // USB-UART RX
    output wire RsTx   // USB-UART TX
);
    
    // Simple loopback assignment for testing
    assign RsTx = RsRx; 

endmodule
