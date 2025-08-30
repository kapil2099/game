`timescale 1ns / 1ps

module axi_lite_spi_master #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5,
    parameter integer DATA_WIDTH         = 32,
    parameter integer MAX_SLAVES         = 8,
    parameter integer FIFO_DEPTH         = 16,
    parameter integer CLK_DIV_WIDTH      = 8
)(
    // AXI4-Lite Slave Interface
    input  wire                                 S_AXI_ACLK,
    input  wire                                 S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        S_AXI_AWADDR,
    input  wire                                 S_AXI_AWVALID,
    output wire                                 S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]        S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]      S_AXI_WSTRB,
    input  wire                                 S_AXI_WVALID,
    output wire                                 S_AXI_WREADY,
    output wire [1:0]                           S_AXI_BRESP,
    output wire                                 S_AXI_BVALID,
    input  wire                                 S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        S_AXI_ARADDR,
    input  wire                                 S_AXI_ARVALID,
    output wire                                 S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0]        S_AXI_RDATA,
    output wire [1:0]                           S_AXI_RRESP,
    output wire                                 S_AXI_RVALID,
    input  wire                                 S_AXI_RREADY,

    // SPI Interface
    output wire                                 spi_sclk,
    output wire                                 spi_mosi,
    input  wire                                 spi_miso,
    output wire [MAX_SLAVES-1:0]                spi_ss_n
);

    // Register Address Map
    localparam integer ADDR_CONTROL      = 5'h00;
    localparam integer ADDR_CLK_DIVIDER  = 5'h04;
    localparam integer ADDR_TX_DATA      = 5'h08;
    localparam integer ADDR_RX_DATA      = 5'h0C;
    localparam integer ADDR_STATUS       = 5'h10;

    // Internal Signals
    reg  [C_S_AXI_ADDR_WIDTH-1:0]       axi_awaddr;
    reg                                 axi_awready;
    reg                                 axi_wready;
    reg  [1:0]                          axi_bresp;
    reg                                 axi_bvalid;
    reg  [C_S_AXI_ADDR_WIDTH-1:0]       axi_araddr;
    reg                                 axi_arready;
    reg  [C_S_AXI_DATA_WIDTH-1:0]       axi_rdata;
    reg  [1:0]                          axi_rresp;
    reg                                 axi_rvalid;

    // SPI Master Control Registers
    reg                                 spi_enable;
    reg  [1:0]                          spi_mode;
    reg  [1:0]                          spi_word_length;
    reg  [$clog2(MAX_SLAVES)-1:0]       spi_slave_select;
    reg  [CLK_DIV_WIDTH-1:0]            spi_clk_divider;
    reg  [DATA_WIDTH-1:0]               spi_tx_data;
    reg                                 spi_tx_valid;

    // SPI Master Status Wires
    wire                                spi_tx_ready;
    wire [DATA_WIDTH-1:0]               spi_rx_data;
    wire                                spi_rx_valid;
    wire                                spi_busy;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_SLAVES(MAX_SLAVES),
        .FIFO_DEPTH(FIFO_DEPTH),
        .CLK_DIV_WIDTH(CLK_DIV_WIDTH)
    ) spi_master_inst (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .spi_mode(spi_mode),
        .clk_divider(spi_clk_divider),
        .slave_select(spi_slave_select),
        .word_length(spi_word_length),
        .enable(spi_enable),
        .tx_data(spi_tx_data),
        .tx_valid(spi_tx_valid),
        .tx_ready(spi_tx_ready),
        .rx_data(spi_rx_data),
        .rx_valid(spi_rx_valid),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss_n(spi_ss_n),
        .busy(spi_busy)
    );

    // AXI Write Logic
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID) begin
                axi_awaddr  <= S_AXI_AWADDR;
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end

            if (~axi_wready && S_AXI_WVALID) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            spi_enable       <= 1'b0;
            spi_mode         <= 2'b00;
            spi_word_length  <= 2'b00;
            spi_slave_select <= 0;
            spi_clk_divider  <= 0;
            spi_tx_data      <= 0;
            spi_tx_valid     <= 1'b0;
        end else begin
            if (axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID) begin
                case (axi_awaddr)
                    ADDR_CONTROL: begin
                        spi_enable       <= S_AXI_WDATA[0];
                        spi_mode         <= S_AXI_WDATA[2:1];
                        spi_word_length  <= S_AXI_WDATA[4:3];
                        spi_slave_select <= S_AXI_WDATA[7:5];
                    end
                    ADDR_CLK_DIVIDER:
                        spi_clk_divider  <= S_AXI_WDATA[CLK_DIV_WIDTH-1:0];
                    ADDR_TX_DATA: begin
                        spi_tx_data      <= S_AXI_WDATA;
                        spi_tx_valid     <= 1'b1;
                    end
                endcase
            end else begin
                spi_tx_valid <= 1'b0;
            end
        end
    end

    // AXI Read Logic
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rresp   <= 2'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_araddr  <= S_AXI_ARADDR;
                axi_arready <= 1'b1;
                axi_rvalid  <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
                axi_rvalid  <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rdata <= 0;
        end else begin
            if (axi_arready) begin
                case (axi_araddr)
                    ADDR_CONTROL:
                        axi_rdata <= {24'b0, spi_slave_select, spi_word_length, spi_mode, spi_enable};
                    ADDR_CLK_DIVIDER:
                        axi_rdata <= {{(32-CLK_DIV_WIDTH){1'b0}}, spi_clk_divider};
                    ADDR_RX_DATA:
                        axi_rdata <= spi_rx_data;
                    ADDR_STATUS:
                        axi_rdata <= {29'b0, spi_rx_valid, spi_tx_ready, spi_busy};
                    default:
                        axi_rdata <= 0;
                endcase
            end
        end
    end

endmodule
