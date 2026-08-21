module uart_echo (
    input clk,          // 12MHz clock on Cmod A7 typically, or scaled
    input RsRx,         // Pin mapped to USB-UART RX
    output RsTx         // Pin mapped to USB-UART TX
);
    // Wire up internal RX data and valid signals from a standard UART RX/TX core
    wire [7:0] rx_byte;
    wire rx_dv;

    // Clock division for 115200 baud from 12 MHz
    // 12MHz / 115200 baud = ~104 cycles per bit
    localparam CLK_PER_BIT = 104;
    
    uart_rx #(.CLK_PER_BIT(CLK_PER_BIT)) UART_RX_Inst (
        .clk(clk),
        .i_Rx_Serial(RsRx),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );

    uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) UART_TX_Inst (
        .clk(clk),
        .i_Tx_DV(rx_dv),       // Echo back immediately when data is valid
        .i_Tx_Byte(rx_byte),
        .o_Tx_Serial(RsTx),
        .o_Tx_Done()
    );
endmodule

// --- UART RECEIVER MODULE ---
module uart_rx #(parameter CLK_PER_BIT = 1250) (
    input        clk,
    input        i_Rx_Serial,
    output       o_Rx_DV,
    output [7:0] o_Rx_Byte
);
    parameter S_IDLE         = 3'b000;
    parameter STATE_RX_START_BIT = 3'b001;
    parameter STATE_RX_DATA_BITS = 3'b010;
    parameter STATE_RX_STOP_BIT  = 3'b011;
    parameter STATE_CLEANUP      = 3'b100;
   
    reg        r_Rx_Data_R = 1'b1;
    reg        r_Rx_Data   = 1'b1;
    reg [15:0] clk_count = 0;
    reg [2:0]  r_Bit_Index = 0;
    reg [7:0]  r_Rx_Byte   = 0;
    reg        r_Rx_DV     = 0;
    reg [2:0]  r_SM_Main   = 0;

    always @(posedge clk) begin
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
    end

    always @(posedge clk) begin
        case (r_SM_Main)
            S_IDLE : begin
                r_Rx_DV     <= 1'b0;
                clk_count <= 0;
                r_Bit_Index <= 0;
                if (r_Rx_Data == 1'b0) r_SM_Main <= STATE_RX_START_BIT;
                else                   r_SM_Main <= S_IDLE;
            end
            STATE_RX_START_BIT : begin
                if (clk_count == (CLK_PER_BIT-1)/2) begin
                    if (r_Rx_Data == 1'b0) begin
                        clk_count <= 0;
                        r_SM_Main   <= STATE_RX_DATA_BITS;
                    end else r_SM_Main <= S_IDLE;
                end else begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_RX_START_BIT;
                end
            end
            STATE_RX_DATA_BITS : begin
                if (clk_count < CLK_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_RX_DATA_BITS;
                end else begin
                    clk_count          <= 0;
                    r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main   <= STATE_RX_DATA_BITS;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= STATE_RX_STOP_BIT;
                    end
                end
            end
            STATE_RX_STOP_BIT : begin
                if (clk_count < CLK_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_RX_STOP_BIT;
                end else begin
                    r_Rx_DV     <= 1'b1;
                    clk_count <= 0;
                    r_SM_Main   <= STATE_CLEANUP;
                end
            end
            STATE_CLEANUP : begin
                r_SM_Main <= S_IDLE;
                r_Rx_DV   <= 1'b0;
            end
            default : r_SM_Main <= S_IDLE;
        endcase
    end
    assign o_Rx_DV   = r_Rx_DV;
    assign o_Rx_Byte = r_Rx_Byte;
endmodule

// --- UART TRANSMITTER MODULE ---
module uart_tx #(parameter CLK_PER_BIT = 1250) (
    input       clk,
    input       i_Tx_DV,
    input [7:0] i_Tx_Byte,
    output      o_Tx_Serial,
    output      o_Tx_Done
);
    parameter S_IDLE         = 3'b000;
    parameter STATE_TX_START_BIT = 3'b001;
    parameter STATE_TX_DATA_BITS = 3'b010;
    parameter STATE_TX_STOP_BIT  = 3'b011;
    parameter STATE_CLEANUP      = 3'b100;

    reg [2:0]  r_SM_Main     = 0;
    reg [15:0] clk_count   = 0;
    reg [2:0]  r_Bit_Index   = 0;
    reg [7:0]  r_Tx_Data     = 0;
    reg        r_Tx_Serial   = 1'b1;
    reg        r_Tx_Done     = 1'b0;

    always @(posedge clk) begin
        case (r_SM_Main)
            S_IDLE : begin
                r_Tx_Serial   <= 1'b1;
                r_Tx_Done     <= 1'b0;
                clk_count   <= 0;
                r_Bit_Index   <= 0;
                if (i_Tx_DV == 1'b1) begin
                    r_Tx_Data <= i_Tx_Byte;
                    r_SM_Main <= STATE_TX_START_BIT;
                end else r_SM_Main <= S_IDLE;
            end
            STATE_TX_START_BIT : begin
                r_Tx_Serial <= 1'b0;
                if (clk_count < CLK_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_TX_START_BIT;
                end else begin
                    clk_count <= 0;
                    r_SM_Main   <= STATE_TX_DATA_BITS;
                end
            end
            STATE_TX_DATA_BITS : begin
                r_Tx_Serial <= r_Tx_Data[r_Bit_Index];
                if (clk_count < CLK_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_TX_DATA_BITS;
                end else begin
                    clk_count <= 0;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main   <= STATE_TX_DATA_BITS;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= STATE_TX_STOP_BIT;
                    end
                end
            end
            STATE_TX_STOP_BIT : begin
                r_Tx_Serial <= 1'b1;
                if (clk_count < CLK_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                    r_SM_Main   <= STATE_TX_STOP_BIT;
                end else begin
                    r_Tx_Done   <= 1'b1;
                    clk_count <= 0;
                    r_SM_Main   <= STATE_CLEANUP;
                end
            end
            STATE_CLEANUP : begin
                r_Tx_Done <= 1'b1;
                r_SM_Main <= S_IDLE;
            end
            default : r_SM_Main <= S_IDLE;
        endcase
    end
    assign o_Tx_Serial = r_Tx_Serial;
    assign o_Tx_Done   = r_Tx_Done;
endmodule
