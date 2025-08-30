module uart_tx #(
    parameter CLKS_PER_BIT = 1042
)(
    input        i_clk,
    input        i_tx_dv,
    input  [7:0] i_tx_byte,
    output       o_tx_active,
    output reg   o_tx_serial,
    output       o_tx_done
);

    localparam S_IDLE = 0;
    localparam S_START_BIT = 1;
    localparam S_DATA_BITS = 2;
    localparam S_STOP_BIT = 3;
    localparam S_DONE = 4;

    reg [2:0] r_state = S_IDLE;
    reg [10:0] r_clk_count = 0;
    reg [2:0] r_bit_index = 0;
    reg [7:0] r_tx_byte = 0;

    assign o_tx_active = (r_state != S_IDLE);
    assign o_tx_done = (r_state == S_DONE);

    always @(posedge i_clk) begin
        case (r_state)
            S_IDLE: begin
                o_tx_serial <= 1'b1;
                r_clk_count <= 0;
                r_bit_index <= 0;
                if (i_tx_dv) begin
                    r_tx_byte <= i_tx_byte;
                    r_state <= S_START_BIT;
                end
            end

            S_START_BIT: begin
                o_tx_serial <= 1'b0;
                if (r_clk_count == CLKS_PER_BIT - 1) begin
                    r_clk_count <= 0;
                    r_state <= S_DATA_BITS;
                end else begin
                    r_clk_count <= r_clk_count + 1;
                end
            end

            S_DATA_BITS: begin
                o_tx_serial <= r_tx_byte[r_bit_index];
                if (r_clk_count == CLKS_PER_BIT - 1) begin
                    r_clk_count <= 0;
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
                o_tx_serial <= 1'b1;
                if (r_clk_count == CLKS_PER_BIT - 1) begin
                    r_clk_count <= 0;
                    r_state <= S_DONE;
                end else begin
                    r_clk_count <= r_clk_count + 1;
                end
            end

            S_DONE: begin
                r_state <= S_IDLE;
            end

            default:
                r_state <= S_IDLE;
        endcase
    end

endmodule
