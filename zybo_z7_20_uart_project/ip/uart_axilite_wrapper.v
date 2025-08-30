module uart_axilite_wrapper (
    // AXI-Lite Interface
    input             s_axi_aclk,
    input             s_axi_aresetn,
    input       [3:0] s_axi_awaddr,
    input             s_axi_awvalid,
    output            s_axi_awready,
    input       [31:0]s_axi_wdata,
    input       [3:0] s_axi_wstrb,
    input             s_axi_wvalid,
    output            s_axi_wready,
    output      [1:0] s_axi_bresp,
    output            s_axi_bvalid,
    input             s_axi_bready,
    input       [3:0] s_axi_araddr,
    input             s_axi_arvalid,
    output            s_axi_arready,
    output      [31:0]s_axi_rdata,
    output      [1:0] s_axi_rresp,
    output            s_axi_rvalid,
    input             s_axi_rready,

    // UART Interface
    input             i_rxd,
    output            o_txd,

    // Interrupt
    output            interrupt
);

    // AXI-Lite signals
    reg [3:0] axi_awaddr;
    reg       axi_awready;
    reg       axi_wready;
    reg [1:0] axi_bresp;
    reg       axi_bvalid;
    reg [3:0] axi_araddr;
    reg       axi_arready;
    reg [31:0]axi_rdata;
    reg [1:0] axi_rresp;
    reg       axi_rvalid;

    // Register map
    localparam ADDR_TX_DATA = 4'h0;
    localparam ADDR_RX_DATA = 4'h4;
    localparam ADDR_STATUS  = 4'h8;

    // Internal registers
    reg [7:0] r_tx_data = 8'h00;
    reg       r_tx_dv = 1'b0;

    wire [7:0] w_rx_byte;
    wire      w_rx_dv;
    wire      w_tx_active;

    // UART Instantiation
    localparam CLKS_PER_BIT = 10417; // 100MHz / 9600 baud

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_tx_inst (
        .i_clk(s_axi_aclk),
        .i_tx_dv(r_tx_dv),
        .i_tx_byte(s_axi_wdata[7:0]),
        .o_tx_active(w_tx_active),
        .o_tx_serial(o_txd),
        .o_tx_done()
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uart_rx_inst (
        .i_clk(s_axi_aclk),
        .i_rx_serial(i_rxd),
        .o_rx_dv(w_rx_dv),
        .o_rx_byte(w_rx_byte)
    );

    // AXI Write Logic
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_awready <= 1'b0;
            axi_wready <= 1'b0;
            axi_bvalid <= 1'b0;
            axi_bresp <= 2'b0;
            r_tx_dv <= 1'b0;
        end else begin
            // awready logic
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end

            // wready logic
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end

            // bvalid logic
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0; // OKAY
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end

            // Generate tx_dv pulse
            r_tx_dv <= 1'b0;
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
                if(s_axi_awaddr == ADDR_TX_DATA) begin
                    r_tx_dv <= 1'b1;
                end
            end
        end
    end

    // AXI Read Logic
    always @(posedge s_axi_aclk) begin
        if (s_axi_aresetn == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b0;
            axi_rdata <= 32'b0;
        end else begin
            // arready logic
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end

            // rvalid logic
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0; // OKAY
                case (s_axi_araddr)
                    ADDR_RX_DATA: axi_rdata <= {24'b0, w_rx_byte};
                    ADDR_STATUS:  axi_rdata <= {30'b0, w_rx_dv, w_tx_active};
                    default:      axi_rdata <= 32'b0;
                endcase
            end else if (s_axi_rready && axi_rvalid) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_bresp = axi_bresp;
    assign s_axi_arready = axi_arready;
    assign s_axi_rvalid = axi_rvalid;
    assign s_axi_rresp = axi_rresp;
    assign s_axi_rdata = axi_rdata;

    // Interrupt on rx_dv
    assign interrupt = w_rx_dv;

endmodule
