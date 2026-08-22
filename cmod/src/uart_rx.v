module uart_rx #(parameter CLK_PER_BIT = 868) (
    // default: 100,000,000 / 115200 = ~868.05
    input  wire           clk,
        input  wire       arstn,
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

    always @(posedge clk or negedge arstn) begin
        if (!arstn) begin
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
