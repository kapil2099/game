/*
 * spi_master.v
 *
 * A synthesizable SPI Master module in Verilog, specifically for SPI Mode 0.
 *
 * Features:
 * - Implements SPI Mode 0 (CPOL=0, CPHA=0).
 * - Configurable clock divider to generate SCLK frequency.
 * - Configurable data word length (8, 16, or 32 bits).
 * - Independent Transmit (TX) and Receive (RX) FIFOs for buffered communication.
 * - Status signals for busy, tx_ready, and rx_valid.
 */
module spi_master #(
    parameter DATA_WIDTH     = 32,          // Support 8/16/32-bit transfers
    parameter MAX_SLAVES     = 8,           // Number of slave devices
    parameter FIFO_DEPTH     = 16,          // TX/RX FIFO depth
    parameter CLK_DIV_WIDTH  = 8,           // Clock divider width
    parameter DELAY_CYCLES   = 0            // Not implemented
)(
    // System Clock and Reset
    input  wire                         clk,
    input  wire                         rst_n,

    // Configuration (spi_mode is ignored, hardcoded to Mode 0)
    input  wire [1:0]                   spi_mode,
    input  wire [CLK_DIV_WIDTH-1:0]     clk_divider,
    input  wire [$clog2(MAX_SLAVES)-1:0] slave_select,
    input  wire [1:0]                   word_length,
    input  wire                         enable,

    // Data Interface
    input  wire [DATA_WIDTH-1:0]        tx_data,
    input  wire                         tx_valid,
    output wire                         tx_ready,
    output wire [DATA_WIDTH-1:0]        rx_data,
    output wire                         rx_valid,

    // SPI Interface
    output wire                         spi_sclk,
    output wire                         spi_mosi,
    input  wire                         spi_miso,
    output wire [MAX_SLAVES-1:0]        spi_ss_n,

    // Status
    output wire                         busy,
    output wire [3:0]                   status_led
);

    //--------------------------------------------------------------------------
    // Internal Signals and Registers
    //--------------------------------------------------------------------------
    localparam FIFO_PTR_WIDTH = $clog2(FIFO_DEPTH);

    // State machine
    localparam [1:0] S_IDLE        = 2'b00;
    localparam [1:0] S_TRANSFER    = 2'b01;
    localparam [1:0] S_UNLOAD      = 2'b10;

    reg [1:0] state = S_IDLE;

    // Data shift registers
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;

    // Bit counter
    reg [$clog2(DATA_WIDTH):0] bit_count;
    wire [4:0] num_bits = (word_length == 2'b00) ? 5'd8 :
                          (word_length == 2'b01) ? 5'd16 : 5'd32;

    // SCLK generation
    reg [CLK_DIV_WIDTH-1:0] clk_div_counter;
    reg sclk_reg = 0; // Mode 0: CPOL=0
    wire sclk_rising_edge;
    wire sclk_falling_edge;

    //--------------------------------------------------------------------------
    // TX FIFO
    //--------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] tx_fifo[FIFO_DEPTH-1:0];
    reg [FIFO_PTR_WIDTH-1:0] tx_fifo_wr_ptr = 0;
    reg [FIFO_PTR_WIDTH-1:0] tx_fifo_rd_ptr = 0;
    reg [$clog2(FIFO_DEPTH)+1:0] tx_fifo_count = 0;

    assign tx_ready = (tx_fifo_count < FIFO_DEPTH);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_wr_ptr <= 0;
        end else if (tx_valid && tx_ready && enable) begin
            tx_fifo[tx_fifo_wr_ptr] <= tx_data;
            tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
        end
    end

    //--------------------------------------------------------------------------
    // RX FIFO
    //--------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] rx_fifo[FIFO_DEPTH-1:0];
    reg [FIFO_PTR_WIDTH-1:0] rx_fifo_wr_ptr = 0;
    reg [FIFO_PTR_WIDTH-1:0] rx_fifo_rd_ptr = 0;
    reg [$clog2(FIFO_DEPTH)+1:0] rx_fifo_count = 0;

    assign rx_valid = (rx_fifo_count > 0);
    assign rx_data = rx_fifo[rx_fifo_rd_ptr];

    // In this simple design, data is popped from RX FIFO when the AXI wrapper reads it.
    // The AXI wrapper should toggle a read enable signal (not implemented here for simplicity).
    // For this test, we assume the C code will read the data once rx_valid is high.
    // To make this synthesizable without latches, we'll pop on the next transaction start.
    wire rx_pop = (state == S_IDLE && rx_valid && ~busy);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_fifo_rd_ptr <= 0;
        end else if (rx_pop) begin
            rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
        end
    end

    //--------------------------------------------------------------------------
    // FIFO Counters
    //--------------------------------------------------------------------------
    wire tx_push = tx_valid && tx_ready && enable;
    wire tx_pop = (state == S_IDLE && tx_fifo_count > 0 && enable);
    wire rx_push = (state == S_UNLOAD);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_count <= 0;
            rx_fifo_count <= 0;
        end else begin
            if (tx_push && !tx_pop) tx_fifo_count <= tx_fifo_count + 1;
            else if (!tx_push && tx_pop) tx_fifo_count <= tx_fifo_count - 1;

            if (rx_push && !rx_pop) rx_fifo_count <= rx_fifo_count + 1;
            else if (!rx_push && rx_pop) rx_fifo_count <= rx_fifo_count - 1;
        end
    end

    //--------------------------------------------------------------------------
    // SPI Clock Generation
    //--------------------------------------------------------------------------
    assign sclk_rising_edge = (clk_div_counter == clk_divider);
    assign sclk_falling_edge = (clk_div_counter == (clk_divider * 2) + 1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_counter <= 0;
            sclk_reg <= 0;
        end else if (enable && state == S_TRANSFER) begin
            if (sclk_falling_edge) begin
                clk_div_counter <= 0;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end

            if (sclk_rising_edge) sclk_reg <= 1;
            if (sclk_falling_edge) sclk_reg <= 0;
        end else begin
            clk_div_counter <= 0;
            sclk_reg <= 0; // Mode 0: Idles low
        end
    end
    assign spi_sclk = sclk_reg;

    //--------------------------------------------------------------------------
    // Main State Machine & Data Shifting
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            bit_count <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_fifo_wr_ptr <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (enable && tx_fifo_count > 0) begin
                        state <= S_TRANSFER;
                        tx_shift_reg <= tx_fifo[tx_fifo_rd_ptr];
                        tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
                        bit_count <= num_bits - 1;
                        rx_shift_reg <= 0; // Clear receive buffer
                    end
                end

                S_TRANSFER: begin
                    // Mode 0: Data is valid on MOSI before rising SCLK edge.
                    // Data is stable on MOSI during rising SCLK edge.
                    // Data on MISO is sampled on the rising SCLK edge.
                    if (sclk_rising_edge) begin
                        rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], spi_miso};
                    end

                    // Data on MOSI is changed after the falling SCLK edge.
                    if (sclk_falling_edge) begin
                        tx_shift_reg <= tx_shift_reg << 1;
                        if (bit_count == 0) begin
                            state <= S_UNLOAD;
                        end else begin
                            bit_count <= bit_count - 1;
                        end
                    end
                end

                S_UNLOAD: begin
                    rx_fifo[rx_fifo_wr_ptr] <= rx_shift_reg;
                    rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

    //--------------------------------------------------------------------------
    // Output Assignments
    //--------------------------------------------------------------------------
    assign spi_mosi = tx_shift_reg[DATA_WIDTH-1];
    assign spi_ss_n = (state == S_IDLE) ? ~0 : ~(1 << slave_select);
    assign busy = (state != S_IDLE);
    assign status_led = 0; // Not implemented

endmodule
