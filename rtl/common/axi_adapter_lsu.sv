`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: axi_adapter_lsu
// Description:
//   Protocol and Data-Width Converter bridging VeeR EL2 64-bit LSU AXI4
//   transactions to the 32-bit AXI System Interconnect (Port S01).
//
// Capabilities:
//   - Supports byte (size=0), halfword (size=1), word (size=2), and doubleword
//     (size=3) reads and writes.
//   - Aligns 32-bit data and write strobes based on addr[2].
//   - For 64-bit transfers (size=3), automatically performs two sequential
//     32-bit transactions to addr and addr+4.
//   - Independent Write and Read state machines allowing concurrent access.
//   - Preserves AXI ID tags and returns correct B and R channel responses.
// ============================================================================

module axi_adapter_lsu #(
    parameter TAG_WIDTH    = 3,             // pt.LSU_BUS_TAG
    parameter ID_WIDTH     = 8,             // Interconnect ID width
    parameter ADDR_WIDTH   = 32,
    parameter S_DATA_WIDTH = 64,            // Core LSU side
    parameter M_DATA_WIDTH = 32             // Interconnect side
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ------------------------------------------------------------------------
    // Core VeeR EL2 LSU Side (64-bit AXI4)
    // ------------------------------------------------------------------------
    // Write Address Channel
    input  wire                     lsu_axi_awvalid,
    output reg                      lsu_axi_awready,
    input  wire [TAG_WIDTH-1:0]     lsu_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    lsu_axi_awaddr,
    input  wire [3:0]               lsu_axi_awregion,
    input  wire [7:0]               lsu_axi_awlen,
    input  wire [2:0]               lsu_axi_awsize,
    input  wire [1:0]               lsu_axi_awburst,
    input  wire                     lsu_axi_awlock,
    input  wire [3:0]               lsu_axi_awcache,
    input  wire [2:0]               lsu_axi_awprot,
    input  wire [3:0]               lsu_axi_awqos,

    // Write Data Channel
    input  wire                     lsu_axi_wvalid,
    output reg                      lsu_axi_wready,
    input  wire [S_DATA_WIDTH-1:0]  lsu_axi_wdata,
    input  wire [S_DATA_WIDTH/8-1:0] lsu_axi_wstrb,
    input  wire                     lsu_axi_wlast,

    // Write Response Channel
    output reg                      lsu_axi_bvalid,
    input  wire                     lsu_axi_bready,
    output reg  [1:0]               lsu_axi_bresp,
    output reg  [TAG_WIDTH-1:0]     lsu_axi_bid,

    // Read Address Channel
    input  wire                     lsu_axi_arvalid,
    output reg                      lsu_axi_arready,
    input  wire [TAG_WIDTH-1:0]     lsu_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    lsu_axi_araddr,
    input  wire [3:0]               lsu_axi_arregion,
    input  wire [7:0]               lsu_axi_arlen,
    input  wire [2:0]               lsu_axi_arsize,
    input  wire [1:0]               lsu_axi_arburst,
    input  wire                     lsu_axi_arlock,
    input  wire [3:0]               lsu_axi_arcache,
    input  wire [2:0]               lsu_axi_arprot,
    input  wire [3:0]               lsu_axi_arqos,

    // Read Data Channel
    output reg                      lsu_axi_rvalid,
    input  wire                     lsu_axi_rready,
    output reg  [TAG_WIDTH-1:0]     lsu_axi_rid,
    output reg  [S_DATA_WIDTH-1:0]  lsu_axi_rdata,
    output reg  [1:0]               lsu_axi_rresp,
    output reg                      lsu_axi_rlast,

    // ------------------------------------------------------------------------
    // Interconnect S01 Side (32-bit AXI4)
    // ------------------------------------------------------------------------
    // Write Address Channel
    output reg                      m_axi_awvalid,
    input  wire                     m_axi_awready,
    output wire [ID_WIDTH-1:0]      m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output wire [7:0]               m_axi_awlen,
    output reg  [2:0]               m_axi_awsize,
    output wire [1:0]               m_axi_awburst,
    output wire                     m_axi_awlock,
    output wire [3:0]               m_axi_awcache,
    output reg  [2:0]               m_axi_awprot,
    output wire [3:0]               m_axi_awqos,

    // Write Data Channel
    output reg                      m_axi_wvalid,
    input  wire                     m_axi_wready,
    output reg  [M_DATA_WIDTH-1:0]  m_axi_wdata,
    output reg  [M_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                     m_axi_wlast,

    // Write Response Channel
    input  wire                     m_axi_bvalid,
    output reg                      m_axi_bready,
    input  wire [1:0]               m_axi_bresp,
    input  wire [ID_WIDTH-1:0]      m_axi_bid,

    // Read Address Channel
    output reg                      m_axi_arvalid,
    input  wire                     m_axi_arready,
    output wire [ID_WIDTH-1:0]      m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]    m_axi_araddr,
    output wire [7:0]               m_axi_arlen,
    output reg  [2:0]               m_axi_arsize,
    output wire [1:0]               m_axi_arburst,
    output wire                     m_axi_arlock,
    output wire [3:0]               m_axi_arcache,
    output reg  [2:0]               m_axi_arprot,
    output wire [3:0]               m_axi_arqos,

    // Read Data Channel
    input  wire                     m_axi_rvalid,
    output reg                      m_axi_rready,
    input  wire [ID_WIDTH-1:0]      m_axi_rid,
    input  wire [M_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]               m_axi_rresp,
    input  wire                     m_axi_rlast
);

    // Constant interconnect drive attributes
    assign m_axi_awlen   = 8'd0;
    assign m_axi_awburst = 2'b01;
    assign m_axi_awlock  = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awqos   = 4'b0;
    assign m_axi_wlast   = 1'b1;

    assign m_axi_arlen   = 8'd0;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock  = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arqos   = 4'b0;

    // ========================================================================
    // Write Channel FSM
    // ========================================================================
    localparam WR_IDLE      = 3'd0;
    localparam WR_SINGLE_TX = 3'd1;
    localparam WR_RESP      = 3'd2;
    localparam WR_D0_TX     = 3'd3;
    localparam WR_D0_RESP   = 3'd4;
    localparam WR_D1_TX     = 3'd5;
    localparam WR_D1_RESP   = 3'd6;
    localparam WR_DONE      = 3'd7;

    reg [2:0]            wr_state;
    reg [ADDR_WIDTH-1:0] saved_awaddr;
    reg [TAG_WIDTH-1:0]  saved_awid;
    reg [2:0]            saved_awsize;
    reg [S_DATA_WIDTH-1:0] saved_wdata;
    reg [S_DATA_WIDTH/8-1:0] saved_wstrb;
    reg                  aw_sent;
    reg                  w_sent;
    reg [1:0]            saved_bresp;

    assign m_axi_awid = {{(ID_WIDTH-TAG_WIDTH){1'b0}}, saved_awid};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state        <= WR_IDLE;
            lsu_axi_awready <= 1'b1;
            lsu_axi_wready  <= 1'b1;
            lsu_axi_bvalid  <= 1'b0;
            lsu_axi_bresp   <= 2'b00;
            lsu_axi_bid     <= {TAG_WIDTH{1'b0}};
            m_axi_awvalid   <= 1'b0;
            m_axi_awaddr    <= {ADDR_WIDTH{1'b0}};
            m_axi_awsize    <= 3'b010;
            m_axi_awprot    <= 3'b0;
            m_axi_wvalid    <= 1'b0;
            m_axi_wdata     <= {M_DATA_WIDTH{1'b0}};
            m_axi_wstrb     <= {M_DATA_WIDTH/8{1'b0}};
            m_axi_bready    <= 1'b0;
            saved_awaddr    <= {ADDR_WIDTH{1'b0}};
            saved_awid      <= {TAG_WIDTH{1'b0}};
            saved_awsize    <= 3'b010;
            saved_wdata     <= {S_DATA_WIDTH{1'b0}};
            saved_wstrb     <= {S_DATA_WIDTH/8{1'b0}};
            aw_sent         <= 1'b0;
            w_sent          <= 1'b0;
            saved_bresp     <= 2'b00;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    lsu_axi_bvalid  <= 1'b0;
                    m_axi_awvalid   <= 1'b0;
                    m_axi_wvalid    <= 1'b0;
                    m_axi_bready    <= 1'b0;
                    aw_sent         <= 1'b0;
                    w_sent          <= 1'b0;

                    if (lsu_axi_awvalid && lsu_axi_wvalid && lsu_axi_awready && lsu_axi_wready) begin
                        saved_awaddr    <= lsu_axi_awaddr;
                        saved_awid      <= lsu_axi_awid;
                        saved_awsize    <= lsu_axi_awsize;
                        saved_wdata     <= lsu_axi_wdata;
                        saved_wstrb     <= lsu_axi_wstrb;
                        m_axi_awprot    <= lsu_axi_awprot;
                        lsu_axi_awready <= 1'b0;
                        lsu_axi_wready  <= 1'b0;

                        if (lsu_axi_awsize == 3'b011) begin
                            // 64-bit store: start first beat at offset 0
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr  <= {lsu_axi_awaddr[31:3], 3'b000};
                            m_axi_awsize  <= 3'b010; // 32-bit beat
                            m_axi_wvalid  <= 1'b1;
                            m_axi_wdata   <= lsu_axi_wdata[31:0];
                            m_axi_wstrb   <= lsu_axi_wstrb[3:0];
                            wr_state      <= WR_D0_TX;
                        end else begin
                            // 32-bit or sub-word store
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr  <= lsu_axi_awaddr;
                            m_axi_awsize  <= lsu_axi_awsize;
                            m_axi_wvalid  <= 1'b1;
                            if (lsu_axi_awaddr[2] == 1'b1) begin
                                m_axi_wdata <= lsu_axi_wdata[63:32];
                                m_axi_wstrb <= lsu_axi_wstrb[7:4];
                            end else begin
                                m_axi_wdata <= lsu_axi_wdata[31:0];
                                m_axi_wstrb <= lsu_axi_wstrb[3:0];
                            end
                            wr_state      <= WR_SINGLE_TX;
                        end
                    end else begin
                        lsu_axi_awready <= 1'b1;
                        lsu_axi_wready  <= 1'b1;
                    end
                end

                WR_SINGLE_TX: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_sent       <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid  <= 1'b0;
                        w_sent        <= 1'b1;
                    end

                    if ((aw_sent || (m_axi_awvalid && m_axi_awready)) &&
                        (w_sent  || (m_axi_wvalid  && m_axi_wready))) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid  <= 1'b0;
                        m_axi_bready  <= 1'b1;
                        wr_state      <= WR_RESP;
                    end
                end

                WR_RESP: begin
                    m_axi_bready <= 1'b1;
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready   <= 1'b0;
                        lsu_axi_bvalid <= 1'b1;
                        lsu_axi_bresp  <= m_axi_bresp;
                        lsu_axi_bid    <= saved_awid;
                        wr_state       <= WR_DONE;
                    end
                end

                // 64-bit store handling
                WR_D0_TX: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_sent       <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid  <= 1'b0;
                        w_sent        <= 1'b1;
                    end

                    if ((aw_sent || (m_axi_awvalid && m_axi_awready)) &&
                        (w_sent  || (m_axi_wvalid  && m_axi_wready))) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid  <= 1'b0;
                        m_axi_bready  <= 1'b1;
                        aw_sent       <= 1'b0;
                        w_sent        <= 1'b0;
                        wr_state      <= WR_D0_RESP;
                    end
                end

                WR_D0_RESP: begin
                    m_axi_bready <= 1'b1;
                    if (m_axi_bvalid && m_axi_bready) begin
                        saved_bresp   <= m_axi_bresp;
                        m_axi_bready  <= 1'b0;
                        // Start second 32-bit beat at offset +4
                        m_axi_awvalid <= 1'b1;
                        m_axi_awaddr  <= {saved_awaddr[31:3], 3'b000} + 4;
                        m_axi_awsize  <= 3'b010;
                        m_axi_wvalid  <= 1'b1;
                        m_axi_wdata   <= saved_wdata[63:32];
                        m_axi_wstrb   <= saved_wstrb[7:4];
                        wr_state      <= WR_D1_TX;
                    end
                end

                WR_D1_TX: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        aw_sent       <= 1'b1;
                    end
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid  <= 1'b0;
                        w_sent        <= 1'b1;
                    end

                    if ((aw_sent || (m_axi_awvalid && m_axi_awready)) &&
                        (w_sent  || (m_axi_wvalid  && m_axi_wready))) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid  <= 1'b0;
                        m_axi_bready  <= 1'b1;
                        wr_state      <= WR_D1_RESP;
                    end
                end

                WR_D1_RESP: begin
                    m_axi_bready <= 1'b1;
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready   <= 1'b0;
                        lsu_axi_bvalid <= 1'b1;
                        lsu_axi_bresp  <= (saved_bresp != 2'b00) ? saved_bresp : m_axi_bresp;
                        lsu_axi_bid    <= saved_awid;
                        wr_state       <= WR_DONE;
                    end
                end

                WR_DONE: begin
                    if (lsu_axi_bvalid && lsu_axi_bready) begin
                        lsu_axi_bvalid  <= 1'b0;
                        lsu_axi_awready <= 1'b1;
                        lsu_axi_wready  <= 1'b1;
                        wr_state        <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // ========================================================================
    // Read Channel FSM
    // ========================================================================
    localparam RD_IDLE      = 3'd0;
    localparam RD_SINGLE_AR = 3'd1;
    localparam RD_SINGLE_R  = 3'd2;
    localparam RD_D0_AR     = 3'd3;
    localparam RD_D0_R      = 3'd4;
    localparam RD_D1_AR     = 3'd5;
    localparam RD_D1_R      = 3'd6;
    localparam RD_DONE      = 3'd7;

    reg [2:0]            rd_state;
    reg [ADDR_WIDTH-1:0] saved_araddr;
    reg [TAG_WIDTH-1:0]  saved_arid;
    reg [2:0]            saved_arsize;
    reg [M_DATA_WIDTH-1:0] rd_data_lo;
    reg [M_DATA_WIDTH-1:0] rd_data_hi;
    reg [1:0]            rd_resp_lo;

    assign m_axi_arid = {{(ID_WIDTH-TAG_WIDTH){1'b0}}, saved_arid};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state        <= RD_IDLE;
            lsu_axi_arready <= 1'b1;
            lsu_axi_rvalid  <= 1'b0;
            lsu_axi_rid     <= {TAG_WIDTH{1'b0}};
            lsu_axi_rdata   <= {S_DATA_WIDTH{1'b0}};
            lsu_axi_rresp   <= 2'b00;
            lsu_axi_rlast   <= 1'b0;
            m_axi_arvalid   <= 1'b0;
            m_axi_araddr    <= {ADDR_WIDTH{1'b0}};
            m_axi_arsize    <= 3'b010;
            m_axi_arprot    <= 3'b0;
            m_axi_rready    <= 1'b0;
            saved_araddr    <= {ADDR_WIDTH{1'b0}};
            saved_arid      <= {TAG_WIDTH{1'b0}};
            saved_arsize    <= 3'b010;
            rd_data_lo      <= {M_DATA_WIDTH{1'b0}};
            rd_data_hi      <= {M_DATA_WIDTH{1'b0}};
            rd_resp_lo      <= 2'b00;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    lsu_axi_rvalid  <= 1'b0;
                    lsu_axi_rlast   <= 1'b0;
                    m_axi_arvalid   <= 1'b0;
                    m_axi_rready    <= 1'b0;

                    if (lsu_axi_arvalid && lsu_axi_arready) begin
                        saved_araddr    <= lsu_axi_araddr;
                        saved_arid      <= lsu_axi_arid;
                        saved_arsize    <= lsu_axi_arsize;
                        m_axi_arprot    <= lsu_axi_arprot;
                        lsu_axi_arready <= 1'b0;

                        if (lsu_axi_arsize == 3'b011) begin
                            // 64-bit load
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr  <= {lsu_axi_araddr[31:3], 3'b000};
                            m_axi_arsize  <= 3'b010;
                            rd_state      <= RD_D0_AR;
                        end else begin
                            // 32-bit or sub-word load
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr  <= lsu_axi_araddr;
                            m_axi_arsize  <= lsu_axi_arsize;
                            rd_state      <= RD_SINGLE_AR;
                        end
                    end else begin
                        lsu_axi_arready <= 1'b1;
                    end
                end

                RD_SINGLE_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        rd_state      <= RD_SINGLE_R;
                    end
                end

                RD_SINGLE_R: begin
                    m_axi_rready <= 1'b1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready   <= 1'b0;
                        lsu_axi_rvalid <= 1'b1;
                        // Replicate word on both halves so LSU receives data regardless of addr[2]
                        lsu_axi_rdata  <= {m_axi_rdata, m_axi_rdata};
                        lsu_axi_rresp  <= m_axi_rresp;
                        lsu_axi_rid    <= saved_arid;
                        lsu_axi_rlast  <= 1'b1;
                        rd_state       <= RD_DONE;
                    end
                end

                // 64-bit load handling
                RD_D0_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        rd_state      <= RD_D0_R;
                    end
                end

                RD_D0_R: begin
                    m_axi_rready <= 1'b1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        rd_data_lo    <= m_axi_rdata;
                        rd_resp_lo    <= m_axi_rresp;
                        m_axi_rready  <= 1'b0;
                        // Issue second beat at offset +4
                        m_axi_arvalid <= 1'b1;
                        m_axi_araddr  <= {saved_araddr[31:3], 3'b000} + 4;
                        m_axi_arsize  <= 3'b010;
                        rd_state      <= RD_D1_AR;
                    end
                end

                RD_D1_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        rd_state      <= RD_D1_R;
                    end
                end

                RD_D1_R: begin
                    m_axi_rready <= 1'b1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready   <= 1'b0;
                        lsu_axi_rvalid <= 1'b1;
                        lsu_axi_rdata  <= {m_axi_rdata, rd_data_lo};
                        lsu_axi_rresp  <= (rd_resp_lo != 2'b00) ? rd_resp_lo : m_axi_rresp;
                        lsu_axi_rid    <= saved_arid;
                        lsu_axi_rlast  <= 1'b1;
                        rd_state       <= RD_DONE;
                    end
                end

                RD_DONE: begin
                    if (lsu_axi_rvalid && lsu_axi_rready) begin
                        lsu_axi_rvalid  <= 1'b0;
                        lsu_axi_rlast   <= 1'b0;
                        lsu_axi_arready <= 1'b1;
                        rd_state        <= RD_IDLE;
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
