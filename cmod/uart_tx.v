module uart_tx #(parameter CLKS_PER_BIT = 1250) (
    input       i_Clock,
    input       i_Tx_DV,
    input [7:0] i_Tx_Byte,
    output      o_Tx_Serial,
    output      o_Tx_Done
);
    parameter s_IDLE         = 3'b000;
    parameter s_TX_START_BIT = 3'b001;
    parameter s_TX_DATA_BITS = 3'b010;
    parameter s_TX_STOP_BIT  = 3'b011;
    parameter s_CLEANUP      = 3'b100;

    reg [2:0]  r_SM_Main     = 0;
    reg [15:0] r_Clk_Count   = 0;
    reg [2:0]  r_Bit_Index   = 0;
    reg [7:0]  r_Tx_Data     = 0;
    reg        r_Tx_Serial   = 1'b1;
    reg        r_Tx_Done     = 1'b0;

    always @(posedge i_Clock) begin
        case (r_SM_Main)
            s_IDLE : begin
                r_Tx_Serial   <= 1'b1;
                r_Tx_Done     <= 1'b0;
                r_Clk_Count   <= 0;
                r_Bit_Index   <= 0;
                if (i_Tx_DV == 1'b1) begin
                    r_Tx_Data <= i_Tx_Byte;
                    r_SM_Main <= s_TX_START_BIT;
                end else r_SM_Main <= s_IDLE;
            end
            s_TX_START_BIT : begin
                r_Tx_Serial <= 1'b0;
                if (r_Clk_Count < CLKS_PER_BIT-1) begin
                    r_Clk_Count <= r_Clk_Count + 1;
                    r_SM_Main   <= s_TX_START_BIT;
                end else begin
                    r_Clk_Count <= 0;
                    r_SM_Main   <= s_TX_DATA_BITS;
                end
            end
            s_TX_DATA_BITS : begin
                r_Tx_Serial <= r_Tx_Data[r_Bit_Index];
                if (r_Clk_Count < CLKS_PER_BIT-1) begin
                    r_Clk_Count <= r_Clk_Count + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                end else begin
                    r_Clk_Count <= 0;
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main   <= s_TX_DATA_BITS;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= s_TX_STOP_BIT;
                    end
                end
            end
            s_TX_STOP_BIT : begin
                r_Tx_Serial <= 1'b1;
                if (r_Clk_Count < CLKS_PER_BIT-1) begin
                    r_Clk_Count <= r_Clk_Count + 1;
                    r_SM_Main   <= s_TX_STOP_BIT;
                end else begin
                    r_Tx_Done   <= 1'b1;
                    r_Clk_Count <= 0;
                    r_SM_Main   <= s_CLEANUP;
                end
            end
            s_CLEANUP : begin
                r_Tx_Done <= 1'b1;
                r_SM_Main <= s_IDLE;
            end
            default : r_SM_Main <= s_IDLE;
        endcase
    end
    assign o_Tx_Serial = r_Tx_Serial;
    assign o_Tx_Done   = r_Tx_Done;
endmodule
