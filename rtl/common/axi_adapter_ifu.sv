`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: axi_adapter_ifu
// Description:
//   Protocol and Data-Width Converter bridging VeeR EL2 64-bit IFU AXI4
//   read requests to the 32-bit AXI System Interconnect (Port S00).
//
// Operation:
//   Each 64-bit fetch beat requested by VeeR EL2 IFU (arsize=3, arlen=0) is
//   converted into two sequential 32-bit read accesses (offset 0 and offset +4)
//   on the 32-bit AXI interconnect.
//   The two returned 32-bit words are assembled into 64-bit rdata {word1, word0}
//   and returned to VeeR EL2 with original transaction ID and status response.
// ============================================================================

module axi_adapter_ifu #(
    parameter TAG_WIDTH    = 3,             // pt.IFU_BUS_TAG
    parameter ID_WIDTH     = 8,             // Interconnect ID width
    parameter ADDR_WIDTH   = 32,
    parameter S_DATA_WIDTH = 64,            // Core IFU side
    parameter M_DATA_WIDTH = 32             // Interconnect side
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ------------------------------------------------------------------------
    // Core VeeR EL2 IFU Side (64-bit AXI4 Read Only)
    // ------------------------------------------------------------------------
    input  wire                     ifu_axi_arvalid,
    output reg                      ifu_axi_arready,
    input  wire [TAG_WIDTH-1:0]     ifu_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    ifu_axi_araddr,
    input  wire [2:0]               ifu_axi_arsize,
    input  wire [7:0]               ifu_axi_arlen,
    input  wire [1:0]               ifu_axi_arburst,
    input  wire [2:0]               ifu_axi_arprot,

    output reg                      ifu_axi_rvalid,
    input  wire                     ifu_axi_rready,
    output reg  [TAG_WIDTH-1:0]     ifu_axi_rid,
    output reg  [S_DATA_WIDTH-1:0]  ifu_axi_rdata,
    output reg  [1:0]               ifu_axi_rresp,
    output reg                      ifu_axi_rlast,

    // ------------------------------------------------------------------------
    // Interconnect S00 Side (32-bit AXI4 Read Channel)
    // ------------------------------------------------------------------------
    output reg                      m_axi_arvalid,
    input  wire                     m_axi_arready,
    output wire [ID_WIDTH-1:0]      m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]    m_axi_araddr,
    output wire [7:0]               m_axi_arlen,
    output wire [2:0]               m_axi_arsize,
    output wire [1:0]               m_axi_arburst,
    output wire                     m_axi_arlock,
    output wire [3:0]               m_axi_arcache,
    output reg  [2:0]               m_axi_arprot,
    output wire [3:0]               m_axi_arqos,

    input  wire                     m_axi_rvalid,
    output reg                      m_axi_rready,
    input  wire [ID_WIDTH-1:0]      m_axi_rid,
    input  wire [M_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]               m_axi_rresp,
    input  wire                     m_axi_rlast
);

    // Constant interconnect drive attributes
    assign m_axi_arlen   = 8'd0;       // Single beat
    assign m_axi_arsize  = 3'b010;     // 4 bytes = 32 bits
    assign m_axi_arburst = 2'b01;     // INCR
    assign m_axi_arlock  = 1'b0;
    assign m_axi_arcache = 4'b0011;    // Normal non-cacheable bufferable
    assign m_axi_arqos   = 4'b0;

    localparam ST_IDLE = 3'd0;
    localparam ST_AR0  = 3'd1;
    localparam ST_R0   = 3'd2;
    localparam ST_AR1  = 3'd3;
    localparam ST_R1   = 3'd4;
    localparam ST_RESP = 3'd5;

    reg [2:0]            state;
    reg [ADDR_WIDTH-1:0] saved_addr;
    reg [TAG_WIDTH-1:0]  saved_id;
    reg [M_DATA_WIDTH-1:0] data_lo;
    reg [M_DATA_WIDTH-1:0] data_hi;
    reg [1:0]            resp_lo;
    reg [1:0]            resp_hi;

    assign m_axi_arid = {{(ID_WIDTH-TAG_WIDTH){1'b0}}, saved_id};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            ifu_axi_arready <= 1'b1;
            ifu_axi_rvalid  <= 1'b0;
            ifu_axi_rid     <= {TAG_WIDTH{1'b0}};
            ifu_axi_rdata   <= {S_DATA_WIDTH{1'b0}};
            ifu_axi_rresp   <= 2'b00;
            ifu_axi_rlast   <= 1'b0;
            m_axi_arvalid   <= 1'b0;
            m_axi_araddr    <= {ADDR_WIDTH{1'b0}};
            m_axi_arprot    <= 3'b0;
            m_axi_rready    <= 1'b0;
            saved_addr      <= {ADDR_WIDTH{1'b0}};
            saved_id        <= {TAG_WIDTH{1'b0}};
            data_lo         <= {M_DATA_WIDTH{1'b0}};
            data_hi         <= {M_DATA_WIDTH{1'b0}};
            resp_lo         <= 2'b00;
            resp_hi         <= 2'b00;
        end else begin
            case (state)
                ST_IDLE: begin
                    ifu_axi_rvalid <= 1'b0;
                    ifu_axi_rlast  <= 1'b0;
                    m_axi_arvalid  <= 1'b0;
                    m_axi_rready   <= 1'b0;

                    if (ifu_axi_arvalid && ifu_axi_arready) begin
                        saved_addr      <= {ifu_axi_araddr[31:3], 3'b000};
                        saved_id        <= ifu_axi_arid;
                        m_axi_arprot    <= ifu_axi_arprot;
                        ifu_axi_arready <= 1'b0;

                        // Immediately present first read address
                        m_axi_arvalid   <= 1'b1;
                        m_axi_araddr    <= {ifu_axi_araddr[31:3], 3'b000};
                        state           <= ST_AR0;
                    end else begin
                        ifu_axi_arready <= 1'b1;
                    end
                end

                ST_AR0: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state         <= ST_R0;
                    end
                end

                ST_R0: begin
                    m_axi_rready <= 1'b1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        data_lo       <= m_axi_rdata;
                        resp_lo       <= m_axi_rresp;
                        m_axi_rready  <= 1'b0;

                        // Present second read address
                        m_axi_arvalid <= 1'b1;
                        m_axi_araddr  <= saved_addr + 4;
                        state         <= ST_AR1;
                    end
                end

                ST_AR1: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state         <= ST_R1;
                    end
                end

                ST_R1: begin
                    m_axi_rready <= 1'b1;
                    if (m_axi_rvalid && m_axi_rready) begin
                        data_hi       <= m_axi_rdata;
                        resp_hi       <= m_axi_rresp;
                        m_axi_rready  <= 1'b0;

                        // Present assembled response to core
                        ifu_axi_rvalid <= 1'b1;
                        ifu_axi_rdata  <= {m_axi_rdata, data_lo};
                        ifu_axi_rid    <= saved_id;
                        ifu_axi_rresp  <= (resp_lo != 2'b00) ? resp_lo : m_axi_rresp;
                        ifu_axi_rlast  <= 1'b1;
                        state          <= ST_RESP;
                    end
                end

                ST_RESP: begin
                    if (ifu_axi_rvalid && ifu_axi_rready) begin
                        ifu_axi_rvalid  <= 1'b0;
                        ifu_axi_rlast   <= 1'b0;
                        ifu_axi_arready <= 1'b1;
                        state           <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
