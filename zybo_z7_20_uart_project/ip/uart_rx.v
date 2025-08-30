module uart_rx #(
    parameter CLKS_PER_BIT = 1042
)(
    input        i_clk,
    input        i_rx_serial,
    output reg   o_rx_dv,
    output reg [7:0] o_rx_byte
);

    localparam S_IDLE = 0;
    localparam S_START_BIT = 1;
    localparam S_DATA_BITS = 2;
    localparam S_STOP_BIT = 3;

    reg [2:0] r_state = S_IDLE;
    reg [10:0] r_clk_count = 0;
    reg [2:0] r_bit_index = 0;
    reg [7:0] r_rx_byte = 0;

    always @(posedge i_clk) begin
        o_rx_dv <= 1'b0;
        case (r_state)
            S_IDLE: begin
                if (~i_rx_serial) begin
                    r_state <= S_START_BIT;
                    r_clk_count <= 0;
                end
            end

            S_START_BIT: begin
                if (r_clk_count == (CLKS_PER_BIT / 2)) begin
                    if (~i_rx_serial) begin
                        r_clk_count <= 0;
                        r_state <= S_DATA_BITS;
                        r_bit_index <= 0;
                    end else begin
                        r_state <= S_IDLE;
                    end
                end else begin
                    r_clk_count <= r_clk_count + 1;
                end
            end

            S_DATA_BITS: begin
                if (r_clk_count == CLKS_PER_BIT - 1) begin
                    r_clk_count <= 0;
                    r_rx_byte[r_bit_index] <= i_rx_serial;
                    if (r_bit_index == 7) begin
                        r_state <= S_STOP_BIT;
                    end else begin
                        r_bit_index <= r_bit_index + 1;
                    end
                end else begin
                    r_clk_count <= r_clk_count + 1;
                end
            end

            S_STOP_BIT: begin
                if (r_clk_count == CLKS_PER_BIT - 1) begin
                    r_clk_count <= 0;
                    o_rx_dv <= 1'b1;
                    o_rx_byte <= r_rx_byte;
                    r_state <= S_IDLE;
                end else begin
                    r_clk_count <= r_clk_count + 1;
                end
            end

            default:
                r_state <= S_IDLE;
        endcase
    end

endmodule
