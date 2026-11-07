`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// File: soc_top.sv
// Project: Complete RISC-V SoC Integration (Option B: AXI-Based Architecture)
//
// Top-Level System-on-Chip integrating:
//   - Real VeeR EL2 RISC-V Processor Core (RV32IMC)
//   - AXI4 Protocol Adapters for IFU and LSU (64-bit to 32-bit conversion)
//   - 2-Master x 8-Slave AXI Interconnect Crossbar
//   - 64 KB Instruction Memory (IMEM) at 0x0000_0000 - 0x0000_FFFF
//   - 64 KB Data Memory (DMEM) at 0x0001_0000 - 0x0001_FFFF
//   - UART IP at 0x4000_0000 - 0x4000_0FFF
//   - SPI IP at 0x4000_1000 - 0x4000_1FFF
//   - I2C IP at 0x4000_2000 - 0x4000_2FFF
//   - PWM IP at 0x4000_3000 - 0x4000_3FFF
//   - Timer IP at 0x4000_4000 - 0x4000_4FFF
//   - GPIO IP at 0x4000_5000 - 0x4000_5FFF
//   - Four Peripheral Interrupts routed to VeeR EL2 PIC external interrupt vector
// ============================================================================

`include "common_defines.vh"

module soc_top
import el2_pkg::*;
#(
`include "el2_param.vh",
    parameter DATA_WIDTH     = 32,
    parameter ADDR_WIDTH     = 32,
    parameter IC_ID_WIDTH    = 8,
    parameter UART_ID_WIDTH  = 12,
    parameter SPI_ID_WIDTH   = 12,
    parameter SPI_ADDR_WIDTH = 7,
    parameter I2C_ID_WIDTH   = 12,
    parameter PWM_ID_WIDTH   = 8,
    parameter IMEM_INIT_FILE = "",
    parameter DMEM_INIT_FILE = ""
)(
    input  wire         clk,
    input  wire         rst,            // Active-high reset

    // ------------------------------------------------------------------------
    // UART external pins
    // ------------------------------------------------------------------------
    input  wire         uart_rx_i,
    output wire         uart_tx_o,
    output wire         uart_interrupt_o,

    // ------------------------------------------------------------------------
    // SPI external pins
    // ------------------------------------------------------------------------
    output wire         spi_clk_o,
    output wire         spi_cs_n_o,
    output wire         spi_mosi_o,
    input  wire         spi_miso_i,
    output wire         spi_interrupt_o,

    // ------------------------------------------------------------------------
    // I2C external pins (open-drain)
    // ------------------------------------------------------------------------
    inout  wire         i2c_scl_io,
    inout  wire         i2c_sda_io,
    output wire         i2c_interrupt_o,

    // ------------------------------------------------------------------------
    // PWM external output
    // ------------------------------------------------------------------------
    output wire         pwm_out_o,

    // ------------------------------------------------------------------------
    // Timer external interrupt
    // ------------------------------------------------------------------------
    output wire         timer_irq_o,

    // ------------------------------------------------------------------------
    // GPIO external pins
    // ------------------------------------------------------------------------
    inout  wire [31:0]  gpio_io,

    // ------------------------------------------------------------------------
    // Processor Trace & Verification Interface
    // ------------------------------------------------------------------------
    output wire [31:0]  trace_rv_i_insn_ip,
    output wire [31:0]  trace_rv_i_address_ip,
    output wire         trace_rv_i_valid_ip,
    output wire         trace_rv_i_exception_ip,
    output wire [4:0]   trace_rv_i_ecause_ip,
    output wire         trace_rv_i_interrupt_ip,
    output wire [31:0]  trace_rv_i_tval_ip
);

    localparam integer STRB_WIDTH = DATA_WIDTH / 8;
    wire rst_n = ~rst;

    // ========================================================================
    // VeeR EL2 Memory Export Interface
    // ========================================================================
    el2_mem_if mem_export ();

    // ========================================================================
    // Processor Bus Signals (Native 64-bit AXI4)
    // ========================================================================
    // LSU AXI
    wire                      lsu_axi_awvalid;
    wire                      lsu_axi_awready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_awid;
    wire [31:0]               lsu_axi_awaddr;
    wire [3:0]                lsu_axi_awregion;
    wire [7:0]                lsu_axi_awlen;
    wire [2:0]                lsu_axi_awsize;
    wire [1:0]                lsu_axi_awburst;
    wire                      lsu_axi_awlock;
    wire [3:0]                lsu_axi_awcache;
    wire [2:0]                lsu_axi_awprot;
    wire [3:0]                lsu_axi_awqos;

    wire                      lsu_axi_wvalid;
    wire                      lsu_axi_wready;
    wire [63:0]               lsu_axi_wdata;
    wire [7:0]                lsu_axi_wstrb;
    wire                      lsu_axi_wlast;

    wire                      lsu_axi_bvalid;
    wire                      lsu_axi_bready;
    wire [1:0]                lsu_axi_bresp;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_bid;

    wire                      lsu_axi_arvalid;
    wire                      lsu_axi_arready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_arid;
    wire [31:0]               lsu_axi_araddr;
    wire [3:0]                lsu_axi_arregion;
    wire [7:0]                lsu_axi_arlen;
    wire [2:0]                lsu_axi_arsize;
    wire [1:0]                lsu_axi_arburst;
    wire                      lsu_axi_arlock;
    wire [3:0]                lsu_axi_arcache;
    wire [2:0]                lsu_axi_arprot;
    wire [3:0]                lsu_axi_arqos;

    wire                      lsu_axi_rvalid;
    wire                      lsu_axi_rready;
    wire [pt.LSU_BUS_TAG-1:0] lsu_axi_rid;
    wire [63:0]               lsu_axi_rdata;
    wire [1:0]                lsu_axi_rresp;
    wire                      lsu_axi_rlast;

    // IFU AXI
    wire                      ifu_axi_arvalid;
    wire                      ifu_axi_arready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_arid;
    wire [31:0]               ifu_axi_araddr;
    wire [3:0]                ifu_axi_arregion;
    wire [7:0]                ifu_axi_arlen;
    wire [2:0]                ifu_axi_arsize;
    wire [1:0]                ifu_axi_arburst;
    wire                      ifu_axi_arlock;
    wire [3:0]                ifu_axi_arcache;
    wire [2:0]                ifu_axi_arprot;
    wire [3:0]                ifu_axi_arqos;

    wire                      ifu_axi_rvalid;
    wire                      ifu_axi_rready;
    wire [pt.IFU_BUS_TAG-1:0] ifu_axi_rid;
    wire [63:0]               ifu_axi_rdata;
    wire [1:0]                ifu_axi_rresp;
    wire                      ifu_axi_rlast;

    // Interrupt vector for VeeR EL2 PIC
    wire [pt.PIC_TOTAL_INT:1] extintsrc_req;
    assign extintsrc_req[1] = timer_irq_o;
    assign extintsrc_req[2] = uart_interrupt_o;
    assign extintsrc_req[3] = spi_interrupt_o;
    assign extintsrc_req[4] = i2c_interrupt_o;
    genvar gi;
    generate
        for (gi = 5; gi <= pt.PIC_TOTAL_INT; gi = gi + 1) begin : g_extint_tieoff
            assign extintsrc_req[gi] = 1'b0;
        end
    endgenerate

    // ========================================================================
    // VeeR EL2 RISC-V Processor Core Instance
    // ========================================================================
    el2_veer_wrapper #(.pt(pt)) cpu_core (
        .clk                    (clk),
        .rst_l                  (rst_n),
        .dbg_rst_l              (rst_n),
        .rst_vec                (31'h0000_0000), // Reset vector = 0x0000_0000 (IMEM start)
        .nmi_int                (1'b0),
        .nmi_vec                (31'h0000_0000),
        .jtag_id                (31'h0000_0000),

        .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip  (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip     (trace_rv_i_tval_ip),

        // LSU AXI4
        .lsu_axi_awvalid        (lsu_axi_awvalid),
        .lsu_axi_awready        (lsu_axi_awready),
        .lsu_axi_awid           (lsu_axi_awid),
        .lsu_axi_awaddr         (lsu_axi_awaddr),
        .lsu_axi_awregion       (lsu_axi_awregion),
        .lsu_axi_awlen          (lsu_axi_awlen),
        .lsu_axi_awsize         (lsu_axi_awsize),
        .lsu_axi_awburst        (lsu_axi_awburst),
        .lsu_axi_awlock         (lsu_axi_awlock),
        .lsu_axi_awcache        (lsu_axi_awcache),
        .lsu_axi_awprot         (lsu_axi_awprot),
        .lsu_axi_awqos          (lsu_axi_awqos),

        .lsu_axi_wvalid         (lsu_axi_wvalid),
        .lsu_axi_wready         (lsu_axi_wready),
        .lsu_axi_wdata          (lsu_axi_wdata),
        .lsu_axi_wstrb          (lsu_axi_wstrb),
        .lsu_axi_wlast          (lsu_axi_wlast),

        .lsu_axi_bvalid         (lsu_axi_bvalid),
        .lsu_axi_bready         (lsu_axi_bready),
        .lsu_axi_bresp          (lsu_axi_bresp),
        .lsu_axi_bid            (lsu_axi_bid),

        .lsu_axi_arvalid        (lsu_axi_arvalid),
        .lsu_axi_arready        (lsu_axi_arready),
        .lsu_axi_arid           (lsu_axi_arid),
        .lsu_axi_araddr         (lsu_axi_araddr),
        .lsu_axi_arregion       (lsu_axi_arregion),
        .lsu_axi_arlen          (lsu_axi_arlen),
        .lsu_axi_arsize         (lsu_axi_arsize),
        .lsu_axi_arburst        (lsu_axi_arburst),
        .lsu_axi_arlock         (lsu_axi_arlock),
        .lsu_axi_arcache        (lsu_axi_arcache),
        .lsu_axi_arprot         (lsu_axi_arprot),
        .lsu_axi_arqos          (lsu_axi_arqos),

        .lsu_axi_rvalid         (lsu_axi_rvalid),
        .lsu_axi_rready         (lsu_axi_rready),
        .lsu_axi_rid            (lsu_axi_rid),
        .lsu_axi_rdata          (lsu_axi_rdata),
        .lsu_axi_rresp          (lsu_axi_rresp),
        .lsu_axi_rlast          (lsu_axi_rlast),

        // IFU AXI4
        .ifu_axi_awvalid        (),
        .ifu_axi_awready        (1'b0),
        .ifu_axi_awid           (),
        .ifu_axi_awaddr         (),
        .ifu_axi_awregion       (),
        .ifu_axi_awlen          (),
        .ifu_axi_awsize         (),
        .ifu_axi_awburst        (),
        .ifu_axi_awlock         (),
        .ifu_axi_awcache        (),
        .ifu_axi_awprot         (),
        .ifu_axi_awqos          (),
        .ifu_axi_wvalid         (),
        .ifu_axi_wready         (1'b0),
        .ifu_axi_wdata          (),
        .ifu_axi_wstrb          (),
        .ifu_axi_wlast          (),
        .ifu_axi_bvalid         (1'b0),
        .ifu_axi_bready         (),
        .ifu_axi_bresp          (2'b00),
        .ifu_axi_bid            ({pt.IFU_BUS_TAG{1'b0}}),

        .ifu_axi_arvalid        (ifu_axi_arvalid),
        .ifu_axi_arready        (ifu_axi_arready),
        .ifu_axi_arid           (ifu_axi_arid),
        .ifu_axi_araddr         (ifu_axi_araddr),
        .ifu_axi_arregion       (ifu_axi_arregion),
        .ifu_axi_arlen          (ifu_axi_arlen),
        .ifu_axi_arsize         (ifu_axi_arsize),
        .ifu_axi_arburst        (ifu_axi_arburst),
        .ifu_axi_arlock         (ifu_axi_arlock),
        .ifu_axi_arcache        (ifu_axi_arcache),
        .ifu_axi_arprot         (ifu_axi_arprot),
        .ifu_axi_arqos          (ifu_axi_arqos),

        .ifu_axi_rvalid         (ifu_axi_rvalid),
        .ifu_axi_rready         (ifu_axi_rready),
        .ifu_axi_rid            (ifu_axi_rid),
        .ifu_axi_rdata          (ifu_axi_rdata),
        .ifu_axi_rresp          (ifu_axi_rresp),
        .ifu_axi_rlast          (ifu_axi_rlast),

        // SB AXI (unused)
        .sb_axi_awvalid         (),
        .sb_axi_awready         (1'b0),
        .sb_axi_awid            (),
        .sb_axi_awaddr          (),
        .sb_axi_awregion        (),
        .sb_axi_awlen           (),
        .sb_axi_awsize          (),
        .sb_axi_awburst         (),
        .sb_axi_awlock          (),
        .sb_axi_awcache         (),
        .sb_axi_awprot          (),
        .sb_axi_awqos           (),
        .sb_axi_wvalid          (),
        .sb_axi_wready          (1'b0),
        .sb_axi_wdata           (),
        .sb_axi_wstrb           (),
        .sb_axi_wlast           (),
        .sb_axi_bvalid          (1'b0),
        .sb_axi_bready          (),
        .sb_axi_bresp           (2'b00),
        .sb_axi_bid             ({pt.SB_BUS_TAG{1'b0}}),
        .sb_axi_arvalid         (),
        .sb_axi_arready         (1'b0),
        .sb_axi_arid            (),
        .sb_axi_araddr          (),
        .sb_axi_arregion        (),
        .sb_axi_arlen           (),
        .sb_axi_arsize          (),
        .sb_axi_arburst         (),
        .sb_axi_arlock          (),
        .sb_axi_arcache         (),
        .sb_axi_arprot          (),
        .sb_axi_arqos           (),
        .sb_axi_rvalid          (1'b0),
        .sb_axi_rready          (),
        .sb_axi_rid             ({pt.SB_BUS_TAG{1'b0}}),
        .sb_axi_rdata           (64'b0),
        .sb_axi_rresp           (2'b00),
        .sb_axi_rlast           (1'b0),

        // DMA AXI (unused slave)
        .dma_axi_awvalid        (1'b0),
        .dma_axi_awready        (),
        .dma_axi_awid           ({pt.DMA_BUS_TAG{1'b0}}),
        .dma_axi_awaddr         (32'b0),
        .dma_axi_awsize         (3'b0),
        .dma_axi_awprot         (3'b0),
        .dma_axi_awlen          (8'b0),
        .dma_axi_awburst        (2'b0),
        .dma_axi_wvalid         (1'b0),
        .dma_axi_wready         (),
        .dma_axi_wdata          (64'b0),
        .dma_axi_wstrb          (8'b0),
        .dma_axi_wlast          (1'b0),
        .dma_axi_bvalid         (),
        .dma_axi_bready         (1'b1),
        .dma_axi_bresp          (),
        .dma_axi_bid            (),
        .dma_axi_arvalid        (1'b0),
        .dma_axi_arready        (),
        .dma_axi_arid           ({pt.DMA_BUS_TAG{1'b0}}),
        .dma_axi_araddr         (32'b0),
        .dma_axi_arsize         (3'b0),
        .dma_axi_arprot         (3'b0),
        .dma_axi_arlen          (8'b0),
        .dma_axi_arburst        (2'b0),
        .dma_axi_rvalid         (),
        .dma_axi_rready         (1'b1),
        .dma_axi_rid            (),
        .dma_axi_rdata          (),
        .dma_axi_rresp          (),
        .dma_axi_rlast          (),

        // Clocks & Enables
        .lsu_bus_clk_en         (1'b1),
        .ifu_bus_clk_en         (1'b1),
        .dbg_bus_clk_en         (1'b1),
        .dma_bus_clk_en         (1'b1),

        .timer_int              (1'b0),
        .soft_int               (1'b0),
        .extintsrc_req          (extintsrc_req),

        .dec_tlu_perfcnt0       (),
        .dec_tlu_perfcnt1       (),
        .dec_tlu_perfcnt2       (),
        .dec_tlu_perfcnt3       (),

        // JTAG / DMI
        .jtag_tck               (1'b0),
        .jtag_tms               (1'b0),
        .jtag_tdi               (1'b0),
        .jtag_trst_n            (rst_n),
        .jtag_tdo               (),
        .jtag_tdoEn             (),
        .core_id                (28'b0),

        // Memory export interfaces
        .el2_mem_export         (mem_export.veer_sram_src),
        .el2_icache_export      (mem_export.veer_icache_src),

        // Control & Run/Halt
        .mpc_debug_halt_req     (1'b0),
        .mpc_debug_run_req      (1'b0),
        .mpc_reset_run_req      (1'b1), // Run immediately upon reset release
        .mpc_debug_halt_ack     (),
        .mpc_debug_run_ack      (),
        .debug_brkpt_status     (),

        .i_cpu_halt_req         (1'b0),
        .o_cpu_halt_ack         (),
        .o_cpu_halt_status      (),
        .o_debug_mode_status    (),
        .i_cpu_run_req          (1'b0),
        .o_cpu_run_ack          (),

        .scan_mode              (1'b0),
        .mbist_mode             (1'b0),

        .dmi_core_enable        (1'b0),
        .dmi_uncore_enable      (1'b0),
        .dmi_uncore_en          (),
        .dmi_uncore_wr_en       (),
        .dmi_uncore_addr        (),
        .dmi_uncore_wdata       (),
        .dmi_uncore_rdata       (32'b0),
        .dmi_active             (),

        .iccm_ecc_single_error  (),
        .iccm_ecc_double_error  (),
        .dccm_ecc_single_error  (),
        .dccm_ecc_double_error  (),
        .dccm_write_readback_error()
    );

    // ========================================================================
    // S00 Interconnect Interface (IFU Adapter -> S00)
    // ========================================================================
    wire [IC_ID_WIDTH-1:0] s00_axi_arid;
    wire [ADDR_WIDTH-1:0]  s00_axi_araddr;
    wire [7:0]             s00_axi_arlen;
    wire [2:0]             s00_axi_arsize;
    wire [1:0]             s00_axi_arburst;
    wire                   s00_axi_arlock;
    wire [3:0]             s00_axi_arcache;
    wire [2:0]             s00_axi_arprot;
    wire [3:0]             s00_axi_arqos;
    wire                   s00_axi_arvalid;
    wire                   s00_axi_arready;
    wire [IC_ID_WIDTH-1:0] s00_axi_rid;
    wire [DATA_WIDTH-1:0]  s00_axi_rdata;
    wire [1:0]             s00_axi_rresp;
    wire                   s00_axi_rlast;
    wire                   s00_axi_rvalid;
    wire                   s00_axi_rready;

    axi_adapter_ifu #(
        .TAG_WIDTH    (pt.IFU_BUS_TAG),
        .ID_WIDTH     (IC_ID_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .S_DATA_WIDTH (64),
        .M_DATA_WIDTH (32)
    ) ifu_adapter (
        .clk             (clk),
        .rst_n           (rst_n),

        // Core IFU
        .ifu_axi_arvalid (ifu_axi_arvalid),
        .ifu_axi_arready (ifu_axi_arready),
        .ifu_axi_arid    (ifu_axi_arid),
        .ifu_axi_araddr  (ifu_axi_araddr),
        .ifu_axi_arsize  (ifu_axi_arsize),
        .ifu_axi_arlen   (ifu_axi_arlen),
        .ifu_axi_arburst (ifu_axi_arburst),
        .ifu_axi_arprot  (ifu_axi_arprot),

        .ifu_axi_rvalid  (ifu_axi_rvalid),
        .ifu_axi_rready  (ifu_axi_rready),
        .ifu_axi_rid     (ifu_axi_rid),
        .ifu_axi_rdata   (ifu_axi_rdata),
        .ifu_axi_rresp   (ifu_axi_rresp),
        .ifu_axi_rlast   (ifu_axi_rlast),

        // Interconnect S00
        .m_axi_arvalid   (s00_axi_arvalid),
        .m_axi_arready   (s00_axi_arready),
        .m_axi_arid      (s00_axi_arid),
        .m_axi_araddr    (s00_axi_araddr),
        .m_axi_arlen     (s00_axi_arlen),
        .m_axi_arsize    (s00_axi_arsize),
        .m_axi_arburst   (s00_axi_arburst),
        .m_axi_arlock    (s00_axi_arlock),
        .m_axi_arcache   (s00_axi_arcache),
        .m_axi_arprot    (s00_axi_arprot),
        .m_axi_arqos     (s00_axi_arqos),

        .m_axi_rvalid    (s00_axi_rvalid),
        .m_axi_rready    (s00_axi_rready),
        .m_axi_rid       (s00_axi_rid),
        .m_axi_rdata     (s00_axi_rdata),
        .m_axi_rresp     (s00_axi_rresp),
        .m_axi_rlast     (s00_axi_rlast)
    );

    // ========================================================================
    // S01 Interconnect Interface (LSU Adapter -> S01)
    // ========================================================================
    wire [IC_ID_WIDTH-1:0] s01_axi_awid;
    wire [ADDR_WIDTH-1:0]  s01_axi_awaddr;
    wire [7:0]             s01_axi_awlen;
    wire [2:0]             s01_axi_awsize;
    wire [1:0]             s01_axi_awburst;
    wire                   s01_axi_awlock;
    wire [3:0]             s01_axi_awcache;
    wire [2:0]             s01_axi_awprot;
    wire [3:0]             s01_axi_awqos;
    wire                   s01_axi_awvalid;
    wire                   s01_axi_awready;

    wire [DATA_WIDTH-1:0]  s01_axi_wdata;
    wire [STRB_WIDTH-1:0]  s01_axi_wstrb;
    wire                   s01_axi_wlast;
    wire                   s01_axi_wvalid;
    wire                   s01_axi_wready;

    wire [IC_ID_WIDTH-1:0] s01_axi_bid;
    wire [1:0]             s01_axi_bresp;
    wire                   s01_axi_bvalid;
    wire                   s01_axi_bready;

    wire [IC_ID_WIDTH-1:0] s01_axi_arid;
    wire [ADDR_WIDTH-1:0]  s01_axi_araddr;
    wire [7:0]             s01_axi_arlen;
    wire [2:0]             s01_axi_arsize;
    wire [1:0]             s01_axi_arburst;
    wire                   s01_axi_arlock;
    wire [3:0]             s01_axi_arcache;
    wire [2:0]             s01_axi_arprot;
    wire [3:0]             s01_axi_arqos;
    wire                   s01_axi_arvalid;
    wire                   s01_axi_arready;

    wire [IC_ID_WIDTH-1:0] s01_axi_rid;
    wire [DATA_WIDTH-1:0]  s01_axi_rdata;
    wire [1:0]             s01_axi_rresp;
    wire                   s01_axi_rlast;
    wire                   s01_axi_rvalid;
    wire                   s01_axi_rready;

    axi_adapter_lsu #(
        .TAG_WIDTH    (pt.LSU_BUS_TAG),
        .ID_WIDTH     (IC_ID_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .S_DATA_WIDTH (64),
        .M_DATA_WIDTH (32)
    ) lsu_adapter (
        .clk             (clk),
        .rst_n           (rst_n),

        // Core LSU
        .lsu_axi_awvalid (lsu_axi_awvalid),
        .lsu_axi_awready (lsu_axi_awready),
        .lsu_axi_awid    (lsu_axi_awid),
        .lsu_axi_awaddr  (lsu_axi_awaddr),
        .lsu_axi_awregion(lsu_axi_awregion),
        .lsu_axi_awlen   (lsu_axi_awlen),
        .lsu_axi_awsize  (lsu_axi_awsize),
        .lsu_axi_awburst (lsu_axi_awburst),
        .lsu_axi_awlock  (lsu_axi_awlock),
        .lsu_axi_awcache (lsu_axi_awcache),
        .lsu_axi_awprot  (lsu_axi_awprot),
        .lsu_axi_awqos   (lsu_axi_awqos),

        .lsu_axi_wvalid  (lsu_axi_wvalid),
        .lsu_axi_wready  (lsu_axi_wready),
        .lsu_axi_wdata   (lsu_axi_wdata),
        .lsu_axi_wstrb   (lsu_axi_wstrb),
        .lsu_axi_wlast   (lsu_axi_wlast),

        .lsu_axi_bvalid  (lsu_axi_bvalid),
        .lsu_axi_bready  (lsu_axi_bready),
        .lsu_axi_bresp   (lsu_axi_bresp),
        .lsu_axi_bid     (lsu_axi_bid),

        .lsu_axi_arvalid (lsu_axi_arvalid),
        .lsu_axi_arready (lsu_axi_arready),
        .lsu_axi_arid    (lsu_axi_arid),
        .lsu_axi_araddr  (lsu_axi_araddr),
        .lsu_axi_arregion(lsu_axi_arregion),
        .lsu_axi_arlen   (lsu_axi_arlen),
        .lsu_axi_arsize  (lsu_axi_arsize),
        .lsu_axi_arburst (lsu_axi_arburst),
        .lsu_axi_arlock  (lsu_axi_arlock),
        .lsu_axi_arcache (lsu_axi_arcache),
        .lsu_axi_arprot  (lsu_axi_arprot),
        .lsu_axi_arqos   (lsu_axi_arqos),

        .lsu_axi_rvalid  (lsu_axi_rvalid),
        .lsu_axi_rready  (lsu_axi_rready),
        .lsu_axi_rid     (lsu_axi_rid),
        .lsu_axi_rdata   (lsu_axi_rdata),
        .lsu_axi_rresp   (lsu_axi_rresp),
        .lsu_axi_rlast   (lsu_axi_rlast),

        // Interconnect S01
        .m_axi_awvalid   (s01_axi_awvalid),
        .m_axi_awready   (s01_axi_awready),
        .m_axi_awid      (s01_axi_awid),
        .m_axi_awaddr    (s01_axi_awaddr),
        .m_axi_awlen     (s01_axi_awlen),
        .m_axi_awsize    (s01_axi_awsize),
        .m_axi_awburst   (s01_axi_awburst),
        .m_axi_awlock    (s01_axi_awlock),
        .m_axi_awcache   (s01_axi_awcache),
        .m_axi_awprot    (s01_axi_awprot),
        .m_axi_awqos     (s01_axi_awqos),

        .m_axi_wvalid    (s01_axi_wvalid),
        .m_axi_wready    (s01_axi_wready),
        .m_axi_wdata     (s01_axi_wdata),
        .m_axi_wstrb     (s01_axi_wstrb),
        .m_axi_wlast     (s01_axi_wlast),

        .m_axi_bvalid    (s01_axi_bvalid),
        .m_axi_bready    (s01_axi_bready),
        .m_axi_bresp     (s01_axi_bresp),
        .m_axi_bid       (s01_axi_bid),

        .m_axi_arvalid   (s01_axi_arvalid),
        .m_axi_arready   (s01_axi_arready),
        .m_axi_arid      (s01_axi_arid),
        .m_axi_araddr    (s01_axi_araddr),
        .m_axi_arlen     (s01_axi_arlen),
        .m_axi_arsize    (s01_axi_arsize),
        .m_axi_arburst   (s01_axi_arburst),
        .m_axi_arlock    (s01_axi_arlock),
        .m_axi_arcache   (s01_axi_arcache),
        .m_axi_arprot    (s01_axi_arprot),
        .m_axi_arqos     (s01_axi_arqos),

        .m_axi_rvalid    (s01_axi_rvalid),
        .m_axi_rready    (s01_axi_rready),
        .m_axi_rid       (s01_axi_rid),
        .m_axi_rdata     (s01_axi_rdata),
        .m_axi_rresp     (s01_axi_rresp),
        .m_axi_rlast     (s01_axi_rlast)
    );

    // ========================================================================
    // Master Port Wires (M00 - M07)
    // ========================================================================
    // M00: IMEM (0x0000_0000)
    wire [IC_ID_WIDTH-1:0] m00_awid;
    wire [ADDR_WIDTH-1:0]  m00_awaddr;
    wire [7:0]             m00_awlen;
    wire [2:0]             m00_awsize;
    wire [1:0]             m00_awburst;
    wire                   m00_awlock;
    wire [3:0]             m00_awcache;
    wire [2:0]             m00_awprot;
    wire [3:0]             m00_awqos;
    wire [3:0]             m00_awregion;
    wire                   m00_awvalid;
    wire                   m00_awready;
    wire [DATA_WIDTH-1:0]  m00_wdata;
    wire [STRB_WIDTH-1:0]  m00_wstrb;
    wire                   m00_wlast;
    wire                   m00_wvalid;
    wire                   m00_wready;
    wire [IC_ID_WIDTH-1:0] m00_bid;
    wire [1:0]             m00_bresp;
    wire                   m00_bvalid;
    wire                   m00_bready;
    wire [IC_ID_WIDTH-1:0] m00_arid;
    wire [ADDR_WIDTH-1:0]  m00_araddr;
    wire [7:0]             m00_arlen;
    wire [2:0]             m00_arsize;
    wire [1:0]             m00_arburst;
    wire                   m00_arlock;
    wire [3:0]             m00_arcache;
    wire [2:0]             m00_arprot;
    wire [3:0]             m00_arqos;
    wire [3:0]             m00_arregion;
    wire                   m00_arvalid;
    wire                   m00_arready;
    wire [IC_ID_WIDTH-1:0] m00_rid;
    wire [DATA_WIDTH-1:0]  m00_rdata;
    wire [1:0]             m00_rresp;
    wire                   m00_rlast;
    wire                   m00_rvalid;
    wire                   m00_rready;

    // M01: Timer (0x4000_4000)
    wire [IC_ID_WIDTH-1:0] m01_awid;
    wire [ADDR_WIDTH-1:0]  m01_awaddr;
    wire [7:0]             m01_awlen;
    wire [2:0]             m01_awsize;
    wire [1:0]             m01_awburst;
    wire                   m01_awlock;
    wire [3:0]             m01_awcache;
    wire [2:0]             m01_awprot;
    wire [3:0]             m01_awqos;
    wire [3:0]             m01_awregion;
    wire                   m01_awvalid;
    wire                   m01_awready;
    wire [DATA_WIDTH-1:0]  m01_wdata;
    wire [STRB_WIDTH-1:0]  m01_wstrb;
    wire                   m01_wlast;
    wire                   m01_wvalid;
    wire                   m01_wready;
    wire [IC_ID_WIDTH-1:0] m01_bid;
    wire [1:0]             m01_bresp;
    wire                   m01_bvalid;
    wire                   m01_bready;
    wire [IC_ID_WIDTH-1:0] m01_arid;
    wire [ADDR_WIDTH-1:0]  m01_araddr;
    wire [7:0]             m01_arlen;
    wire [2:0]             m01_arsize;
    wire [1:0]             m01_arburst;
    wire                   m01_arlock;
    wire [3:0]             m01_arcache;
    wire [2:0]             m01_arprot;
    wire [3:0]             m01_arqos;
    wire [3:0]             m01_arregion;
    wire                   m01_arvalid;
    wire                   m01_arready;
    wire [IC_ID_WIDTH-1:0] m01_rid;
    wire [DATA_WIDTH-1:0]  m01_rdata;
    wire [1:0]             m01_rresp;
    wire                   m01_rlast;
    wire                   m01_rvalid;
    wire                   m01_rready;

    // M02: GPIO (0x4000_5000)
    wire [IC_ID_WIDTH-1:0] m02_awid;
    wire [ADDR_WIDTH-1:0]  m02_awaddr;
    wire [7:0]             m02_awlen;
    wire [2:0]             m02_awsize;
    wire [1:0]             m02_awburst;
    wire                   m02_awlock;
    wire [3:0]             m02_awcache;
    wire [2:0]             m02_awprot;
    wire [3:0]             m02_awqos;
    wire [3:0]             m02_awregion;
    wire                   m02_awvalid;
    wire                   m02_awready;
    wire [DATA_WIDTH-1:0]  m02_wdata;
    wire [STRB_WIDTH-1:0]  m02_wstrb;
    wire                   m02_wlast;
    wire                   m02_wvalid;
    wire                   m02_wready;
    wire [IC_ID_WIDTH-1:0] m02_bid;
    wire [1:0]             m02_bresp;
    wire                   m02_bvalid;
    wire                   m02_bready;
    wire [IC_ID_WIDTH-1:0] m02_arid;
    wire [ADDR_WIDTH-1:0]  m02_araddr;
    wire [7:0]             m02_arlen;
    wire [2:0]             m02_arsize;
    wire [1:0]             m02_arburst;
    wire                   m02_arlock;
    wire [3:0]             m02_arcache;
    wire [2:0]             m02_arprot;
    wire [3:0]             m02_arqos;
    wire [3:0]             m02_arregion;
    wire                   m02_arvalid;
    wire                   m02_arready;
    wire [IC_ID_WIDTH-1:0] m02_rid;
    wire [DATA_WIDTH-1:0]  m02_rdata;
    wire [1:0]             m02_rresp;
    wire                   m02_rlast;
    wire                   m02_rvalid;
    wire                   m02_rready;

    // M03: UART (0x4000_0000)
    wire [IC_ID_WIDTH-1:0] m03_awid;
    wire [ADDR_WIDTH-1:0]  m03_awaddr;
    wire [7:0]             m03_awlen;
    wire [2:0]             m03_awsize;
    wire [1:0]             m03_awburst;
    wire                   m03_awlock;
    wire [3:0]             m03_awcache;
    wire [2:0]             m03_awprot;
    wire [3:0]             m03_awqos;
    wire [3:0]             m03_awregion;
    wire                   m03_awvalid;
    wire                   m03_awready;
    wire [DATA_WIDTH-1:0]  m03_wdata;
    wire [STRB_WIDTH-1:0]  m03_wstrb;
    wire                   m03_wlast;
    wire                   m03_wvalid;
    wire                   m03_wready;
    wire [IC_ID_WIDTH-1:0] m03_bid;
    wire [1:0]             m03_bresp;
    wire                   m03_bvalid;
    wire                   m03_bready;
    wire [IC_ID_WIDTH-1:0] m03_arid;
    wire [ADDR_WIDTH-1:0]  m03_araddr;
    wire [7:0]             m03_arlen;
    wire [2:0]             m03_arsize;
    wire [1:0]             m03_arburst;
    wire                   m03_arlock;
    wire [3:0]             m03_arcache;
    wire [2:0]             m03_arprot;
    wire [3:0]             m03_arqos;
    wire [3:0]             m03_arregion;
    wire                   m03_arvalid;
    wire                   m03_arready;
    wire [IC_ID_WIDTH-1:0] m03_rid;
    wire [DATA_WIDTH-1:0]  m03_rdata;
    wire [1:0]             m03_rresp;
    wire                   m03_rlast;
    wire                   m03_rvalid;
    wire                   m03_rready;

    // M04: SPI (0x4000_1000)
    wire [IC_ID_WIDTH-1:0] m04_awid;
    wire [ADDR_WIDTH-1:0]  m04_awaddr;
    wire [7:0]             m04_awlen;
    wire [2:0]             m04_awsize;
    wire [1:0]             m04_awburst;
    wire                   m04_awlock;
    wire [3:0]             m04_awcache;
    wire [2:0]             m04_awprot;
    wire [3:0]             m04_awqos;
    wire [3:0]             m04_awregion;
    wire                   m04_awvalid;
    wire                   m04_awready;
    wire [DATA_WIDTH-1:0]  m04_wdata;
    wire [STRB_WIDTH-1:0]  m04_wstrb;
    wire                   m04_wlast;
    wire                   m04_wvalid;
    wire                   m04_wready;
    wire [IC_ID_WIDTH-1:0] m04_bid;
    wire [1:0]             m04_bresp;
    wire                   m04_bvalid;
    wire                   m04_bready;
    wire [IC_ID_WIDTH-1:0] m04_arid;
    wire [ADDR_WIDTH-1:0]  m04_araddr;
    wire [7:0]             m04_arlen;
    wire [2:0]             m04_arsize;
    wire [1:0]             m04_arburst;
    wire                   m04_arlock;
    wire [3:0]             m04_arcache;
    wire [2:0]             m04_arprot;
    wire [3:0]             m04_arqos;
    wire [3:0]             m04_arregion;
    wire                   m04_arvalid;
    wire                   m04_arready;
    wire [IC_ID_WIDTH-1:0] m04_rid;
    wire [DATA_WIDTH-1:0]  m04_rdata;
    wire [1:0]             m04_rresp;
    wire                   m04_rlast;
    wire                   m04_rvalid;
    wire                   m04_rready;

    // M05: I2C (0x4000_2000)
    wire [IC_ID_WIDTH-1:0] m05_awid;
    wire [ADDR_WIDTH-1:0]  m05_awaddr;
    wire [7:0]             m05_awlen;
    wire [2:0]             m05_awsize;
    wire [1:0]             m05_awburst;
    wire                   m05_awlock;
    wire [3:0]             m05_awcache;
    wire [2:0]             m05_awprot;
    wire [3:0]             m05_awqos;
    wire [3:0]             m05_awregion;
    wire                   m05_awvalid;
    wire                   m05_awready;
    wire [DATA_WIDTH-1:0]  m05_wdata;
    wire [STRB_WIDTH-1:0]  m05_wstrb;
    wire                   m05_wlast;
    wire                   m05_wvalid;
    wire                   m05_wready;
    wire [IC_ID_WIDTH-1:0] m05_bid;
    wire [1:0]             m05_bresp;
    wire                   m05_bvalid;
    wire                   m05_bready;
    wire [IC_ID_WIDTH-1:0] m05_arid;
    wire [ADDR_WIDTH-1:0]  m05_araddr;
    wire [7:0]             m05_arlen;
    wire [2:0]             m05_arsize;
    wire [1:0]             m05_arburst;
    wire                   m05_arlock;
    wire [3:0]             m05_arcache;
    wire [2:0]             m05_arprot;
    wire [3:0]             m05_arqos;
    wire [3:0]             m05_arregion;
    wire                   m05_arvalid;
    wire                   m05_arready;
    wire [IC_ID_WIDTH-1:0] m05_rid;
    wire [DATA_WIDTH-1:0]  m05_rdata;
    wire [1:0]             m05_rresp;
    wire                   m05_rlast;
    wire                   m05_rvalid;
    wire                   m05_rready;

    // M06: PWM (0x4000_3000)
    wire [IC_ID_WIDTH-1:0] m06_awid;
    wire [ADDR_WIDTH-1:0]  m06_awaddr;
    wire [7:0]             m06_awlen;
    wire [2:0]             m06_awsize;
    wire [1:0]             m06_awburst;
    wire                   m06_awlock;
    wire [3:0]             m06_awcache;
    wire [2:0]             m06_awprot;
    wire [3:0]             m06_awqos;
    wire [3:0]             m06_awregion;
    wire                   m06_awvalid;
    wire                   m06_awready;
    wire [DATA_WIDTH-1:0]  m06_wdata;
    wire [STRB_WIDTH-1:0]  m06_wstrb;
    wire                   m06_wlast;
    wire                   m06_wvalid;
    wire                   m06_wready;
    wire [IC_ID_WIDTH-1:0] m06_bid;
    wire [1:0]             m06_bresp;
    wire                   m06_bvalid;
    wire                   m06_bready;
    wire [IC_ID_WIDTH-1:0] m06_arid;
    wire [ADDR_WIDTH-1:0]  m06_araddr;
    wire [7:0]             m06_arlen;
    wire [2:0]             m06_arsize;
    wire [1:0]             m06_arburst;
    wire                   m06_arlock;
    wire [3:0]             m06_arcache;
    wire [2:0]             m06_arprot;
    wire [3:0]             m06_arqos;
    wire [3:0]             m06_arregion;
    wire                   m06_arvalid;
    wire                   m06_arready;
    wire [IC_ID_WIDTH-1:0] m06_rid;
    wire [DATA_WIDTH-1:0]  m06_rdata;
    wire [1:0]             m06_rresp;
    wire                   m06_rlast;
    wire                   m06_rvalid;
    wire                   m06_rready;

    // M07: DMEM (0x0001_0000)
    wire [IC_ID_WIDTH-1:0] m07_awid;
    wire [ADDR_WIDTH-1:0]  m07_awaddr;
    wire [7:0]             m07_awlen;
    wire [2:0]             m07_awsize;
    wire [1:0]             m07_awburst;
    wire                   m07_awlock;
    wire [3:0]             m07_awcache;
    wire [2:0]             m07_awprot;
    wire [3:0]             m07_awqos;
    wire [3:0]             m07_awregion;
    wire                   m07_awvalid;
    wire                   m07_awready;
    wire [DATA_WIDTH-1:0]  m07_wdata;
    wire [STRB_WIDTH-1:0]  m07_wstrb;
    wire                   m07_wlast;
    wire                   m07_wvalid;
    wire                   m07_wready;
    wire [IC_ID_WIDTH-1:0] m07_bid;
    wire [1:0]             m07_bresp;
    wire                   m07_bvalid;
    wire                   m07_bready;
    wire [IC_ID_WIDTH-1:0] m07_arid;
    wire [ADDR_WIDTH-1:0]  m07_araddr;
    wire [7:0]             m07_arlen;
    wire [2:0]             m07_arsize;
    wire [1:0]             m07_arburst;
    wire                   m07_arlock;
    wire [3:0]             m07_arcache;
    wire [2:0]             m07_arprot;
    wire [3:0]             m07_arqos;
    wire [3:0]             m07_arregion;
    wire                   m07_arvalid;
    wire                   m07_arready;
    wire [IC_ID_WIDTH-1:0] m07_rid;
    wire [DATA_WIDTH-1:0]  m07_rdata;
    wire [1:0]             m07_rresp;
    wire                   m07_rlast;
    wire                   m07_rvalid;
    wire                   m07_rready;

    // ========================================================================
    // AXI 2x8 Interconnect Instance
    // ========================================================================
    axi_interconnect_wrap_2x8 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(IC_ID_WIDTH),

        // M00: IMEM (64 KB: 0x0000_0000 - 0x0000_FFFF)
        .M00_BASE_ADDR(32'h0000_0000), .M00_ADDR_WIDTH(16),
        .M00_CONNECT_READ(2'b11),      .M00_CONNECT_WRITE(2'b10),

        // M01: Timer (4 KB: 0x4000_4000 - 0x4000_4FFF)
        .M01_BASE_ADDR(32'h4000_4000), .M01_ADDR_WIDTH(12),
        .M01_CONNECT_READ(2'b10),      .M01_CONNECT_WRITE(2'b10),

        // M02: GPIO (4 KB: 0x4000_5000 - 0x4000_5FFF)
        .M02_BASE_ADDR(32'h4000_5000), .M02_ADDR_WIDTH(12),
        .M02_CONNECT_READ(2'b10),      .M02_CONNECT_WRITE(2'b10),

        // M03: UART (4 KB: 0x4000_0000 - 0x4000_0FFF)
        .M03_BASE_ADDR(32'h4000_0000), .M03_ADDR_WIDTH(12),
        .M03_CONNECT_READ(2'b10),      .M03_CONNECT_WRITE(2'b10),

        // M04: SPI (4 KB: 0x4000_1000 - 0x4000_1FFF)
        .M04_BASE_ADDR(32'h4000_1000), .M04_ADDR_WIDTH(12),
        .M04_CONNECT_READ(2'b10),      .M04_CONNECT_WRITE(2'b10),

        // M05: I2C (4 KB: 0x4000_2000 - 0x4000_2FFF)
        .M05_BASE_ADDR(32'h4000_2000), .M05_ADDR_WIDTH(12),
        .M05_CONNECT_READ(2'b10),      .M05_CONNECT_WRITE(2'b10),

        // M06: PWM (4 KB: 0x4000_3000 - 0x4000_3FFF)
        .M06_BASE_ADDR(32'h4000_3000), .M06_ADDR_WIDTH(12),
        .M06_CONNECT_READ(2'b10),      .M06_CONNECT_WRITE(2'b10),

        // M07: DMEM (64 KB: 0x0001_0000 - 0x0001_FFFF)
        .M07_BASE_ADDR(32'h0001_0000), .M07_ADDR_WIDTH(16),
        .M07_CONNECT_READ(2'b11),      .M07_CONNECT_WRITE(2'b10)
    ) interconnect_inst (
        .clk(clk),
        .rst(rst),

        // S00: IFU
        .s00_axi_awid(8'b0),        .s00_axi_awaddr(32'b0),
        .s00_axi_awlen(8'b0),       .s00_axi_awsize(3'b0),
        .s00_axi_awburst(2'b0),     .s00_axi_awlock(1'b0),
        .s00_axi_awcache(4'b0),     .s00_axi_awprot(3'b0),
        .s00_axi_awqos(4'b0),       .s00_axi_awuser(1'b0),
        .s00_axi_awvalid(1'b0),     .s00_axi_awready(),
        .s00_axi_wdata(32'b0),      .s00_axi_wstrb(4'b0),
        .s00_axi_wlast(1'b0),       .s00_axi_wuser(1'b0),
        .s00_axi_wvalid(1'b0),      .s00_axi_wready(),
        .s00_axi_bid(),             .s00_axi_bresp(),
        .s00_axi_buser(),           .s00_axi_bvalid(),
        .s00_axi_bready(1'b1),

        .s00_axi_arid(s00_axi_arid),       .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen),     .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst), .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache), .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos),     .s00_axi_aruser(1'b0),
        .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid),         .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),     .s00_axi_rlast(s00_axi_rlast),
        .s00_axi_ruser(),                  .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),

        // S01: LSU
        .s01_axi_awid(s01_axi_awid),       .s01_axi_awaddr(s01_axi_awaddr),
        .s01_axi_awlen(s01_axi_awlen),     .s01_axi_awsize(s01_axi_awsize),
        .s01_axi_awburst(s01_axi_awburst), .s01_axi_awlock(s01_axi_awlock),
        .s01_axi_awcache(s01_axi_awcache), .s01_axi_awprot(s01_axi_awprot),
        .s01_axi_awqos(s01_axi_awqos),     .s01_axi_awuser(1'b0),
        .s01_axi_awvalid(s01_axi_awvalid), .s01_axi_awready(s01_axi_awready),
        .s01_axi_wdata(s01_axi_wdata),     .s01_axi_wstrb(s01_axi_wstrb),
        .s01_axi_wlast(s01_axi_wlast),     .s01_axi_wuser(1'b0),
        .s01_axi_wvalid(s01_axi_wvalid),   .s01_axi_wready(s01_axi_wready),
        .s01_axi_bid(s01_axi_bid),         .s01_axi_bresp(s01_axi_bresp),
        .s01_axi_buser(),                  .s01_axi_bvalid(s01_axi_bvalid),
        .s01_axi_bready(s01_axi_bready),

        .s01_axi_arid(s01_axi_arid),       .s01_axi_araddr(s01_axi_araddr),
        .s01_axi_arlen(s01_axi_arlen),     .s01_axi_arsize(s01_axi_arsize),
        .s01_axi_arburst(s01_axi_arburst), .s01_axi_arlock(s01_axi_arlock),
        .s01_axi_arcache(s01_axi_arcache), .s01_axi_arprot(s01_axi_arprot),
        .s01_axi_arqos(s01_axi_arqos),     .s01_axi_aruser(1'b0),
        .s01_axi_arvalid(s01_axi_arvalid), .s01_axi_arready(s01_axi_arready),
        .s01_axi_rid(s01_axi_rid),         .s01_axi_rdata(s01_axi_rdata),
        .s01_axi_rresp(s01_axi_rresp),     .s01_axi_rlast(s01_axi_rlast),
        .s01_axi_ruser(),                  .s01_axi_rvalid(s01_axi_rvalid),
        .s01_axi_rready(s01_axi_rready),

        // M00: IMEM
        .m00_axi_awid(m00_awid),       .m00_axi_awaddr(m00_awaddr),
        .m00_axi_awlen(m00_awlen),     .m00_axi_awsize(m00_awsize),
        .m00_axi_awburst(m00_awburst), .m00_axi_awlock(m00_awlock),
        .m00_axi_awcache(m00_awcache), .m00_axi_awprot(m00_awprot),
        .m00_axi_awqos(m00_awqos),     .m00_axi_awregion(m00_awregion),
        .m00_axi_awuser(),             .m00_axi_awvalid(m00_awvalid),
        .m00_axi_awready(m00_awready), .m00_axi_wdata(m00_wdata),
        .m00_axi_wstrb(m00_wstrb),     .m00_axi_wlast(m00_wlast),
        .m00_axi_wuser(),              .m00_axi_wvalid(m00_wvalid),
        .m00_axi_wready(m00_wready),   .m00_axi_bid(m00_bid),
        .m00_axi_bresp(m00_bresp),     .m00_axi_buser(1'b0),
        .m00_axi_bvalid(m00_bvalid),   .m00_axi_bready(m00_bready),
        .m00_axi_arid(m00_arid),       .m00_axi_araddr(m00_araddr),
        .m00_axi_arlen(m00_arlen),     .m00_axi_arsize(m00_arsize),
        .m00_axi_arburst(m00_arburst), .m00_axi_arlock(m00_arlock),
        .m00_axi_arcache(m00_arcache), .m00_axi_arprot(m00_arprot),
        .m00_axi_arqos(m00_arqos),     .m00_axi_arregion(m00_arregion),
        .m00_axi_aruser(),             .m00_axi_arvalid(m00_arvalid),
        .m00_axi_arready(m00_arready), .m00_axi_rid(m00_rid),
        .m00_axi_rdata(m00_rdata),     .m00_axi_rresp(m00_rresp),
        .m00_axi_rlast(m00_rlast),     .m00_axi_ruser(1'b0),
        .m00_axi_rvalid(m00_rvalid),   .m00_axi_rready(m00_rready),

        // M01: Timer
        .m01_axi_awid(m01_awid),       .m01_axi_awaddr(m01_awaddr),
        .m01_axi_awlen(m01_awlen),     .m01_axi_awsize(m01_awsize),
        .m01_axi_awburst(m01_awburst), .m01_axi_awlock(m01_awlock),
        .m01_axi_awcache(m01_awcache), .m01_axi_awprot(m01_awprot),
        .m01_axi_awqos(m01_awqos),     .m01_axi_awregion(m01_awregion),
        .m01_axi_awuser(),             .m01_axi_awvalid(m01_awvalid),
        .m01_axi_awready(m01_awready), .m01_axi_wdata(m01_wdata),
        .m01_axi_wstrb(m01_wstrb),     .m01_axi_wlast(m01_wlast),
        .m01_axi_wuser(),              .m01_axi_wvalid(m01_wvalid),
        .m01_axi_wready(m01_wready),   .m01_axi_bid(m01_bid),
        .m01_axi_bresp(m01_bresp),     .m01_axi_buser(1'b0),
        .m01_axi_bvalid(m01_bvalid),   .m01_axi_bready(m01_bready),
        .m01_axi_arid(m01_arid),       .m01_axi_araddr(m01_araddr),
        .m01_axi_arlen(m01_arlen),     .m01_axi_arsize(m01_arsize),
        .m01_axi_arburst(m01_arburst), .m01_axi_arlock(m01_arlock),
        .m01_axi_arcache(m01_arcache), .m01_axi_arprot(m01_arprot),
        .m01_axi_arqos(m01_arqos),     .m01_axi_arregion(m01_arregion),
        .m01_axi_aruser(),             .m01_axi_arvalid(m01_arvalid),
        .m01_axi_arready(m01_arready), .m01_axi_rid(m01_rid),
        .m01_axi_rdata(m01_rdata),     .m01_axi_rresp(m01_rresp),
        .m01_axi_rlast(m01_rlast),     .m01_axi_ruser(1'b0),
        .m01_axi_rvalid(m01_rvalid),   .m01_axi_rready(m01_rready),

        // M02: GPIO
        .m02_axi_awid(m02_awid),       .m02_axi_awaddr(m02_awaddr),
        .m02_axi_awlen(m02_awlen),     .m02_axi_awsize(m02_awsize),
        .m02_axi_awburst(m02_awburst), .m02_axi_awlock(m02_awlock),
        .m02_axi_awcache(m02_awcache), .m02_axi_awprot(m02_awprot),
        .m02_axi_awqos(m02_awqos),     .m02_axi_awregion(m02_awregion),
        .m02_axi_awuser(),             .m02_axi_awvalid(m02_awvalid),
        .m02_axi_awready(m02_awready), .m02_axi_wdata(m02_wdata),
        .m02_axi_wstrb(m02_wstrb),     .m02_axi_wlast(m02_wlast),
        .m02_axi_wuser(),              .m02_axi_wvalid(m02_wvalid),
        .m02_axi_wready(m02_wready),   .m02_axi_bid(m02_bid),
        .m02_axi_bresp(m02_bresp),     .m02_axi_buser(1'b0),
        .m02_axi_bvalid(m02_bvalid),   .m02_axi_bready(m02_bready),
        .m02_axi_arid(m02_arid),       .m02_axi_araddr(m02_araddr),
        .m02_axi_arlen(m02_arlen),     .m02_axi_arsize(m02_arsize),
        .m02_axi_arburst(m02_arburst), .m02_axi_arlock(m02_arlock),
        .m02_axi_arcache(m02_arcache), .m02_axi_arprot(m02_arprot),
        .m02_axi_arqos(m02_arqos),     .m02_axi_arregion(m02_arregion),
        .m02_axi_aruser(),             .m02_axi_arvalid(m02_arvalid),
        .m02_axi_arready(m02_arready), .m02_axi_rid(m02_rid),
        .m02_axi_rdata(m02_rdata),     .m02_axi_rresp(m02_rresp),
        .m02_axi_rlast(m02_rlast),     .m02_axi_ruser(1'b0),
        .m02_axi_rvalid(m02_rvalid),   .m02_axi_rready(m02_rready),

        // M03: UART
        .m03_axi_awid(m03_awid),       .m03_axi_awaddr(m03_awaddr),
        .m03_axi_awlen(m03_awlen),     .m03_axi_awsize(m03_awsize),
        .m03_axi_awburst(m03_awburst), .m03_axi_awlock(m03_awlock),
        .m03_axi_awcache(m03_awcache), .m03_axi_awprot(m03_awprot),
        .m03_axi_awqos(m03_awqos),     .m03_axi_awregion(m03_awregion),
        .m03_axi_awuser(),             .m03_axi_awvalid(m03_awvalid),
        .m03_axi_awready(m03_awready), .m03_axi_wdata(m03_wdata),
        .m03_axi_wstrb(m03_wstrb),     .m03_axi_wlast(m03_wlast),
        .m03_axi_wuser(),              .m03_axi_wvalid(m03_wvalid),
        .m03_axi_wready(m03_wready),   .m03_axi_bid(m03_bid),
        .m03_axi_bresp(m03_bresp),     .m03_axi_buser(1'b0),
        .m03_axi_bvalid(m03_bvalid),   .m03_axi_bready(m03_bready),
        .m03_axi_arid(m03_arid),       .m03_axi_araddr(m03_araddr),
        .m03_axi_arlen(m03_arlen),     .m03_axi_arsize(m03_arsize),
        .m03_axi_arburst(m03_arburst), .m03_axi_arlock(m03_arlock),
        .m03_axi_arcache(m03_arcache), .m03_axi_arprot(m03_arprot),
        .m03_axi_arqos(m03_arqos),     .m03_axi_arregion(m03_arregion),
        .m03_axi_aruser(),             .m03_axi_arvalid(m03_arvalid),
        .m03_axi_arready(m03_arready), .m03_axi_rid(m03_rid),
        .m03_axi_rdata(m03_rdata),     .m03_axi_rresp(m03_rresp),
        .m03_axi_rlast(m03_rlast),     .m03_axi_ruser(1'b0),
        .m03_axi_rvalid(m03_rvalid),   .m03_axi_rready(m03_rready),

        // M04: SPI
        .m04_axi_awid(m04_awid),       .m04_axi_awaddr(m04_awaddr),
        .m04_axi_awlen(m04_awlen),     .m04_axi_awsize(m04_awsize),
        .m04_axi_awburst(m04_awburst), .m04_axi_awlock(m04_awlock),
        .m04_axi_awcache(m04_awcache), .m04_axi_awprot(m04_awprot),
        .m04_axi_awqos(m04_awqos),     .m04_axi_awregion(m04_awregion),
        .m04_axi_awuser(),             .m04_axi_awvalid(m04_awvalid),
        .m04_axi_awready(m04_awready), .m04_axi_wdata(m04_wdata),
        .m04_axi_wstrb(m04_wstrb),     .m04_axi_wlast(m04_wlast),
        .m04_axi_wuser(),              .m04_axi_wvalid(m04_wvalid),
        .m04_axi_wready(m04_wready),   .m04_axi_bid(m04_bid),
        .m04_axi_bresp(m04_bresp),     .m04_axi_buser(1'b0),
        .m04_axi_bvalid(m04_bvalid),   .m04_axi_bready(m04_bready),
        .m04_axi_arid(m04_arid),       .m04_axi_araddr(m04_araddr),
        .m04_axi_arlen(m04_arlen),     .m04_axi_arsize(m04_arsize),
        .m04_axi_arburst(m04_arburst), .m04_axi_arlock(m04_arlock),
        .m04_axi_arcache(m04_arcache), .m04_axi_arprot(m04_arprot),
        .m04_axi_arqos(m04_arqos),     .m04_axi_arregion(m04_arregion),
        .m04_axi_aruser(),             .m04_axi_arvalid(m04_arvalid),
        .m04_axi_arready(m04_arready), .m04_axi_rid(m04_rid),
        .m04_axi_rdata(m04_rdata),     .m04_axi_rresp(m04_rresp),
        .m04_axi_rlast(m04_rlast),     .m04_axi_ruser(1'b0),
        .m04_axi_rvalid(m04_rvalid),   .m04_axi_rready(m04_rready),

        // M05: I2C
        .m05_axi_awid(m05_awid),       .m05_axi_awaddr(m05_awaddr),
        .m05_axi_awlen(m05_awlen),     .m05_axi_awsize(m05_awsize),
        .m05_axi_awburst(m05_awburst), .m05_axi_awlock(m05_awlock),
        .m05_axi_awcache(m05_awcache), .m05_axi_awprot(m05_awprot),
        .m05_axi_awqos(m05_awqos),     .m05_axi_awregion(m05_awregion),
        .m05_axi_awuser(),             .m05_axi_awvalid(m05_awvalid),
        .m05_axi_awready(m05_awready), .m05_axi_wdata(m05_wdata),
        .m05_axi_wstrb(m05_wstrb),     .m05_axi_wlast(m05_wlast),
        .m05_axi_wuser(),              .m05_axi_wvalid(m05_wvalid),
        .m05_axi_wready(m05_wready),   .m05_axi_bid(m05_bid),
        .m05_axi_bresp(m05_bresp),     .m05_axi_buser(1'b0),
        .m05_axi_bvalid(m05_bvalid),   .m05_axi_bready(m05_bready),
        .m05_axi_arid(m05_arid),       .m05_axi_araddr(m05_araddr),
        .m05_axi_arlen(m05_arlen),     .m05_axi_arsize(m05_arsize),
        .m05_axi_arburst(m05_arburst), .m05_axi_arlock(m05_arlock),
        .m05_axi_arcache(m05_arcache), .m05_axi_arprot(m05_arprot),
        .m05_axi_arqos(m05_arqos),     .m05_axi_arregion(m05_arregion),
        .m05_axi_aruser(),             .m05_axi_arvalid(m05_arvalid),
        .m05_axi_arready(m05_arready), .m05_axi_rid(m05_rid),
        .m05_axi_rdata(m05_rdata),     .m05_axi_rresp(m05_rresp),
        .m05_axi_rlast(m05_rlast),     .m05_axi_ruser(1'b0),
        .m05_axi_rvalid(m05_rvalid),   .m05_axi_rready(m05_rready),

        // M06: PWM
        .m06_axi_awid(m06_awid),       .m06_axi_awaddr(m06_awaddr),
        .m06_axi_awlen(m06_awlen),     .m06_axi_awsize(m06_awsize),
        .m06_axi_awburst(m06_awburst), .m06_axi_awlock(m06_awlock),
        .m06_axi_awcache(m06_awcache), .m06_axi_awprot(m06_awprot),
        .m06_axi_awqos(m06_awqos),     .m06_axi_awregion(m06_awregion),
        .m06_axi_awuser(),             .m06_axi_awvalid(m06_awvalid),
        .m06_axi_awready(m06_awready), .m06_axi_wdata(m06_wdata),
        .m06_axi_wstrb(m06_wstrb),     .m06_axi_wlast(m06_wlast),
        .m06_axi_wuser(),              .m06_axi_wvalid(m06_wvalid),
        .m06_axi_wready(m06_wready),   .m06_axi_bid(m06_bid),
        .m06_axi_bresp(m06_bresp),     .m06_axi_buser(1'b0),
        .m06_axi_bvalid(m06_bvalid),   .m06_axi_bready(m06_bready),
        .m06_axi_arid(m06_arid),       .m06_axi_araddr(m06_araddr),
        .m06_axi_arlen(m06_arlen),     .m06_axi_arsize(m06_arsize),
        .m06_axi_arburst(m06_arburst), .m06_axi_arlock(m06_arlock),
        .m06_axi_arcache(m06_arcache), .m06_axi_arprot(m06_arprot),
        .m06_axi_arqos(m06_arqos),     .m06_axi_arregion(m06_arregion),
        .m06_axi_aruser(),             .m06_axi_arvalid(m06_arvalid),
        .m06_axi_arready(m06_arready), .m06_axi_rid(m06_rid),
        .m06_axi_rdata(m06_rdata),     .m06_axi_rresp(m06_rresp),
        .m06_axi_rlast(m06_rlast),     .m06_axi_ruser(1'b0),
        .m06_axi_rvalid(m06_rvalid),   .m06_axi_rready(m06_rready),

        // M07: DMEM
        .m07_axi_awid(m07_awid),       .m07_axi_awaddr(m07_awaddr),
        .m07_axi_awlen(m07_awlen),     .m07_axi_awsize(m07_awsize),
        .m07_axi_awburst(m07_awburst), .m07_axi_awlock(m07_awlock),
        .m07_axi_awcache(m07_awcache), .m07_axi_awprot(m07_awprot),
        .m07_axi_awqos(m07_awqos),     .m07_axi_awregion(m07_awregion),
        .m07_axi_awuser(),             .m07_axi_awvalid(m07_awvalid),
        .m07_axi_awready(m07_awready), .m07_axi_wdata(m07_wdata),
        .m07_axi_wstrb(m07_wstrb),     .m07_axi_wlast(m07_wlast),
        .m07_axi_wuser(),              .m07_axi_wvalid(m07_wvalid),
        .m07_axi_wready(m07_wready),   .m07_axi_bid(m07_bid),
        .m07_axi_bresp(m07_bresp),     .m07_axi_buser(1'b0),
        .m07_axi_bvalid(m07_bvalid),   .m07_axi_bready(m07_bready),
        .m07_axi_arid(m07_arid),       .m07_axi_araddr(m07_araddr),
        .m07_axi_arlen(m07_arlen),     .m07_axi_arsize(m07_arsize),
        .m07_axi_arburst(m07_arburst), .m07_axi_arlock(m07_arlock),
        .m07_axi_arcache(m07_arcache), .m07_axi_arprot(m07_arprot),
        .m07_axi_arqos(m07_arqos),     .m07_axi_arregion(m07_arregion),
        .m07_axi_aruser(),             .m07_axi_arvalid(m07_arvalid),
        .m07_axi_arready(m07_arready), .m07_axi_rid(m07_rid),
        .m07_axi_rdata(m07_rdata),     .m07_axi_rresp(m07_rresp),
        .m07_axi_rlast(m07_rlast),     .m07_axi_ruser(1'b0),
        .m07_axi_rvalid(m07_rvalid),   .m07_axi_rready(m07_rready)
    );

    // ========================================================================
    // M00 Slave: Instruction Memory (IMEM, 64 KB, 0x0000_0000)
    // ========================================================================
    axi_mem_slave #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .STRB_WIDTH     (STRB_WIDTH),
        .ID_WIDTH       (IC_ID_WIDTH),
        .MEM_SIZE_BYTES (65536),
        .BASE_ADDR      (32'h0000_0000),
        .INIT_FILE      (IMEM_INIT_FILE),
        .PLUSARG_NAME   ("IMEM_HEX")
    ) imem_inst (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axi_awid     (m00_awid),
        .s_axi_awaddr   (m00_awaddr),
        .s_axi_awlen    (m00_awlen),
        .s_axi_awsize   (m00_awsize),
        .s_axi_awburst  (m00_awburst),
        .s_axi_awlock   (m00_awlock),
        .s_axi_awcache  (m00_awcache),
        .s_axi_awprot   (m00_awprot),
        .s_axi_awqos    (m00_awqos),
        .s_axi_awregion (m00_awregion),
        .s_axi_awvalid  (m00_awvalid),
        .s_axi_awready  (m00_awready),

        .s_axi_wdata    (m00_wdata),
        .s_axi_wstrb    (m00_wstrb),
        .s_axi_wlast    (m00_wlast),
        .s_axi_wvalid   (m00_wvalid),
        .s_axi_wready   (m00_wready),

        .s_axi_bid      (m00_bid),
        .s_axi_bresp    (m00_bresp),
        .s_axi_bvalid   (m00_bvalid),
        .s_axi_bready   (m00_bready),

        .s_axi_arid     (m00_arid),
        .s_axi_araddr   (m00_araddr),
        .s_axi_arlen    (m00_arlen),
        .s_axi_arsize   (m00_arsize),
        .s_axi_arburst  (m00_arburst),
        .s_axi_arlock   (m00_arlock),
        .s_axi_arcache  (m00_arcache),
        .s_axi_arprot   (m00_arprot),
        .s_axi_arqos    (m00_arqos),
        .s_axi_arregion (m00_arregion),
        .s_axi_arvalid  (m00_arvalid),
        .s_axi_arready  (m00_arready),

        .s_axi_rid      (m00_rid),
        .s_axi_rdata    (m00_rdata),
        .s_axi_rresp    (m00_rresp),
        .s_axi_rlast    (m00_rlast),
        .s_axi_rvalid   (m00_rvalid),
        .s_axi_rready   (m00_rready)
    );

    // ========================================================================
    // M07 Slave: Data Memory (DMEM, 64 KB, 0x0001_0000)
    // ========================================================================
    axi_mem_slave #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .STRB_WIDTH     (STRB_WIDTH),
        .ID_WIDTH       (IC_ID_WIDTH),
        .MEM_SIZE_BYTES (65536),
        .BASE_ADDR      (32'h0001_0000),
        .INIT_FILE      (DMEM_INIT_FILE),
        .PLUSARG_NAME   ("DMEM_HEX")
    ) dmem_inst (
        .clk            (clk),
        .rst_n          (rst_n),

        .s_axi_awid     (m07_awid),
        .s_axi_awaddr   (m07_awaddr),
        .s_axi_awlen    (m07_awlen),
        .s_axi_awsize   (m07_awsize),
        .s_axi_awburst  (m07_awburst),
        .s_axi_awlock   (m07_awlock),
        .s_axi_awcache  (m07_awcache),
        .s_axi_awprot   (m07_awprot),
        .s_axi_awqos    (m07_awqos),
        .s_axi_awregion (m07_awregion),
        .s_axi_awvalid  (m07_awvalid),
        .s_axi_awready  (m07_awready),

        .s_axi_wdata    (m07_wdata),
        .s_axi_wstrb    (m07_wstrb),
        .s_axi_wlast    (m07_wlast),
        .s_axi_wvalid   (m07_wvalid),
        .s_axi_wready   (m07_wready),

        .s_axi_bid      (m07_bid),
        .s_axi_bresp    (m07_bresp),
        .s_axi_bvalid   (m07_bvalid),
        .s_axi_bready   (m07_bready),

        .s_axi_arid     (m07_arid),
        .s_axi_araddr   (m07_araddr),
        .s_axi_arlen    (m07_arlen),
        .s_axi_arsize   (m07_arsize),
        .s_axi_arburst  (m07_arburst),
        .s_axi_arlock   (m07_arlock),
        .s_axi_arcache  (m07_arcache),
        .s_axi_arprot   (m07_arprot),
        .s_axi_arqos    (m07_arqos),
        .s_axi_arregion (m07_arregion),
        .s_axi_arvalid  (m07_arvalid),
        .s_axi_arready  (m07_arready),

        .s_axi_rid      (m07_rid),
        .s_axi_rdata    (m07_rdata),
        .s_axi_rresp    (m07_rresp),
        .s_axi_rlast    (m07_rlast),
        .s_axi_rvalid   (m07_rvalid),
        .s_axi_rready   (m07_rready)
    );

    // ========================================================================
    // M01 Slave: Timer (0x4000_4000)
    // ========================================================================
    reg [IC_ID_WIDTH-1:0] timer_bid_r;
    reg [IC_ID_WIDTH-1:0] timer_rid_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer_bid_r <= {IC_ID_WIDTH{1'b0}};
            timer_rid_r <= {IC_ID_WIDTH{1'b0}};
        end else begin
            if (m01_awvalid && m01_awready)
                timer_bid_r <= m01_awid;
            if (m01_arvalid && m01_arready)
                timer_rid_r <= m01_arid;
        end
    end
    assign m01_bid = timer_bid_r;
    assign m01_rid = timer_rid_r;

    timer_axi timer_inst (
        .aclk       (clk),
        .aresetn    (rst_n),
        .awaddr     (m01_awaddr),
        .awprot     (m01_awprot),
        .awvalid    (m01_awvalid),
        .awready    (m01_awready),
        .wdata      (m01_wdata),
        .wstrb      (m01_wstrb),
        .wvalid     (m01_wvalid),
        .wready     (m01_wready),
        .bresp      (m01_bresp),
        .bvalid     (m01_bvalid),
        .bready     (m01_bready),
        .araddr     (m01_araddr),
        .arprot     (m01_arprot),
        .arvalid    (m01_arvalid),
        .arready    (m01_arready),
        .rdata      (m01_rdata),
        .rresp      (m01_rresp),
        .rvalid     (m01_rvalid),
        .rready     (m01_rready),
        .ext_meas_i (1'b0),
        .capture_i  (1'b0),
        .pwm_o      (),
        .trigger_o  (),
        .irq        (timer_irq_o)
    );
    assign m01_rlast = 1'b1;

    // ========================================================================
    // M02 Slave: GPIO (0x4000_5000)
    // ========================================================================
    reg [IC_ID_WIDTH-1:0] gpio_bid_r;
    reg [IC_ID_WIDTH-1:0] gpio_rid_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gpio_bid_r <= {IC_ID_WIDTH{1'b0}};
            gpio_rid_r <= {IC_ID_WIDTH{1'b0}};
        end else begin
            if (m02_awvalid && m02_awready)
                gpio_bid_r <= m02_awid;
            if (m02_arvalid && m02_arready)
                gpio_rid_r <= m02_arid;
        end
    end
    assign m02_bid = gpio_bid_r;
    assign m02_rid = gpio_rid_r;

    gpio_axi #(
        .NUM_BITS(32)
    ) gpio_inst (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (m02_awaddr),
        .s_axi_awprot  (m02_awprot),
        .s_axi_awvalid (m02_awvalid),
        .s_axi_awready (m02_awready),
        .s_axi_wdata   (m02_wdata),
        .s_axi_wstrb   (m02_wstrb),
        .s_axi_wvalid  (m02_wvalid),
        .s_axi_wready  (m02_wready),
        .s_axi_bresp   (m02_bresp),
        .s_axi_bvalid  (m02_bvalid),
        .s_axi_bready  (m02_bready),
        .s_axi_araddr  (m02_araddr),
        .s_axi_arprot  (m02_arprot),
        .s_axi_arvalid (m02_arvalid),
        .s_axi_arready (m02_arready),
        .s_axi_rdata   (m02_rdata),
        .s_axi_rresp   (m02_rresp),
        .s_axi_rvalid  (m02_rvalid),
        .s_axi_rready  (m02_rready),
        .io            (gpio_io),
        .intr          ()
    );
    assign m02_rlast = 1'b1;

    // ========================================================================
    // M03 Slave: UART (0x4000_0000)
    // ========================================================================
    axi_uart_top uart_inst (
        .fixed_clk_i            (clk),
        .axi_aclk_i             (clk),
        .axi_aresetn_i          (rst_n),
        .axi_arid_i             (m03_arid),
        .axi_araddr_i           (m03_araddr[4:0]),
        .axi_arvalid_i          (m03_arvalid),
        .axi_rready_i           (m03_rready),
        .axi_rresp_o            (m03_rresp),
        .axi_rdata_o            (m03_rdata),
        .axi_rid_o              (m03_rid),
        .axi_rvalid_o           (m03_rvalid),
        .axi_arready_o          (m03_arready),
        .axi_awid_i             (m03_awid),
        .axi_awaddr_i           (m03_awaddr[4:0]),
        .axi_awvalid_i          (m03_awvalid),
        .axi_wdata_i            (m03_wdata),
        .axi_wstrb_i            (m03_wstrb),
        .axi_wvalid_i           (m03_wvalid),
        .axi_bready_i           (m03_bready),
        .axi_bresp_o            (m03_bresp),
        .axi_bid_o              (m03_bid),
        .axi_bvalid_o           (m03_bvalid),
        .axi_awready_o          (m03_awready),
        .axi_wready_o           (m03_wready),
        .uart_rx_i              (uart_rx_i),
        .read_interrupt_o       (uart_interrupt_o),
        .uart_tx_o              (uart_tx_o)
    );
    assign m03_rlast = 1'b1;

    // ========================================================================
    // M04 Slave: SPI (0x4000_1000)
    // ========================================================================
    axi_spi_top spi_inst (
        .fixed_clk_i            (clk),
        .axi_aclk_i             (clk),
        .axi_aresetn_i          (rst_n),
        .axi_arid_i             (m04_arid),
        .axi_araddr_i           (m04_araddr[SPI_ADDR_WIDTH-1:0]),
        .axi_arvalid_i          (m04_arvalid),
        .axi_rready_i           (m04_rready),
        .axi_rresp_o            (m04_rresp),
        .axi_rdata_o            (m04_rdata),
        .axi_rid_o              (m04_rid),
        .axi_rvalid_o           (m04_rvalid),
        .axi_arready_o          (m04_arready),
        .axi_awid_i             (m04_awid),
        .axi_awaddr_i           (m04_awaddr[SPI_ADDR_WIDTH-1:0]),
        .axi_awvalid_i          (m04_awvalid),
        .axi_wdata_i            (m04_wdata),
        .axi_wstrb_i            (m04_wstrb),
        .axi_wvalid_i           (m04_wvalid),
        .axi_bready_i           (m04_bready),
        .axi_bresp_o            (m04_bresp),
        .axi_bid_o              (m04_bid),
        .axi_bvalid_o           (m04_bvalid),
        .axi_awready_o          (m04_awready),
        .axi_wready_o           (m04_wready),
        .spi_clk_o              (spi_clk_o),
        .spi_cs_n_o             (spi_cs_n_o),
        .spi_mosi_o             (spi_mosi_o),
        .spi_miso_i             (spi_miso_i)
    );
    assign m04_rlast = 1'b1;
    // SPI completion interrupt: active when RX data is ready
    assign spi_interrupt_o = ~spi_inst.spi_status_reg[0];

    // ========================================================================
    // M05 Slave: I2C (0x4000_2000) with Inline AXI-to-Wishbone Bridge
    // ========================================================================
    wire        wb_clk   = clk;
    wire        wb_rst   = rst;
    wire        arst_n_i2c = rst_n;
    wire [2:0]  wb_adr;
    wire [7:0]  wb_dat_wr;
    wire [7:0]  wb_dat_rd;
    wire        wb_we;
    wire        wb_stb;
    wire        wb_cyc;
    wire        wb_ack;

    reg [2:0]   fsm_wr;
    reg [2:0]   fsm_rd;

    localparam I2C_WR_IDLE  = 3'd0;
    localparam I2C_WR_SETUP = 3'd1;
    localparam I2C_WR_WAIT  = 3'd2;
    localparam I2C_WR_RESP  = 3'd3;

    localparam I2C_RD_IDLE  = 3'd0;
    localparam I2C_RD_SETUP = 3'd1;
    localparam I2C_RD_WAIT  = 3'd2;
    localparam I2C_RD_RESP  = 3'd3;

    reg [IC_ID_WIDTH-1:0] i2c_wr_id_r, i2c_rd_id_r;
    reg [2:0]             i2c_wr_adr_r, i2c_rd_adr_r;
    reg [7:0]             i2c_wr_dat_r;
    reg [7:0]             i2c_rd_dat_r;

    reg         m05_awready_r;
    reg         m05_wready_r;
    reg         m05_bvalid_r;
    reg [1:0]   m05_bresp_r;
    reg [IC_ID_WIDTH-1:0] m05_bid_r;

    reg         m05_arready_r;
    reg         m05_rvalid_r;
    reg [DATA_WIDTH-1:0]  m05_rdata_r;
    reg [1:0]   m05_rresp_r;
    reg [IC_ID_WIDTH-1:0] m05_rid_r;

    assign m05_awready = m05_awready_r;
    assign m05_wready  = m05_wready_r;
    assign m05_bvalid  = m05_bvalid_r;
    assign m05_bresp   = m05_bresp_r;
    assign m05_bid     = m05_bid_r;

    assign m05_arready = m05_arready_r;
    assign m05_rvalid  = m05_rvalid_r;
    assign m05_rdata   = m05_rdata_r;
    assign m05_rresp   = m05_rresp_r;
    assign m05_rid     = m05_rid_r;
    assign m05_rlast   = 1'b1;

    // AW and W channel buffers - accept independently per AXI spec
    reg        i2c_aw_pending;
    reg        i2c_w_pending;
    reg [7:0]  i2c_wr_dat_buf;
    reg [2:0]  i2c_wr_adr_buf;
    reg [IC_ID_WIDTH-1:0] i2c_wr_id_buf;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_wr        <= I2C_WR_IDLE;
            m05_awready_r <= 1'b0;
            m05_wready_r  <= 1'b0;
            m05_bvalid_r  <= 1'b0;
            m05_bresp_r   <= 2'b00;
            m05_bid_r     <= {IC_ID_WIDTH{1'b0}};
            i2c_wr_id_r   <= {IC_ID_WIDTH{1'b0}};
            i2c_wr_adr_r  <= 3'b0;
            i2c_wr_dat_r  <= 8'b0;
            i2c_aw_pending <= 1'b0;
            i2c_w_pending  <= 1'b0;
            i2c_wr_dat_buf <= 8'b0;
            i2c_wr_adr_buf <= 3'b0;
            i2c_wr_id_buf  <= {IC_ID_WIDTH{1'b0}};
        end else begin
            // Accept AW channel when idle and no pending AW
            if (fsm_wr == I2C_WR_IDLE && m05_awvalid && !i2c_aw_pending) begin
                m05_awready_r  <= 1'b1;
                i2c_wr_adr_buf <= m05_awaddr[4:2];
                i2c_wr_id_buf  <= m05_awid;
                i2c_aw_pending <= 1'b1;
            end else begin
                m05_awready_r <= 1'b0;
            end

            // Accept W channel when idle and no pending W
            if (fsm_wr == I2C_WR_IDLE && m05_wvalid && !i2c_w_pending) begin
                m05_wready_r  <= 1'b1;
                i2c_wr_dat_buf <= m05_wdata[7:0];
                i2c_w_pending  <= 1'b1;
            end else begin
                m05_wready_r <= 1'b0;
            end

            case (fsm_wr)
                I2C_WR_IDLE: begin
                    m05_bvalid_r <= 1'b0;
                    // Start WB transaction once both AW and W have been captured
                    if (i2c_aw_pending && i2c_w_pending && fsm_rd == I2C_RD_IDLE) begin
                        i2c_wr_id_r  <= i2c_wr_id_buf;
                        i2c_wr_adr_r <= i2c_wr_adr_buf;
                        i2c_wr_dat_r <= i2c_wr_dat_buf;
                        i2c_aw_pending <= 1'b0;
                        i2c_w_pending  <= 1'b0;
                        fsm_wr        <= I2C_WR_SETUP;
                    end
                end

                I2C_WR_SETUP: begin
                    fsm_wr <= I2C_WR_WAIT;
                end

                I2C_WR_WAIT: begin
                    if (wb_ack) begin
                        m05_bvalid_r <= 1'b1;
                        m05_bresp_r  <= 2'b00;
                        m05_bid_r    <= i2c_wr_id_r;
                        fsm_wr       <= I2C_WR_RESP;
                    end
                end

                I2C_WR_RESP: begin
                    if (m05_bready) begin
                        m05_bvalid_r <= 1'b0;
                        fsm_wr       <= I2C_WR_IDLE;
                    end
                end

                default: fsm_wr <= I2C_WR_IDLE;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_rd        <= I2C_RD_IDLE;
            m05_arready_r <= 1'b0;
            m05_rvalid_r  <= 1'b0;
            m05_rdata_r   <= {DATA_WIDTH{1'b0}};
            m05_rresp_r   <= 2'b00;
            m05_rid_r     <= {IC_ID_WIDTH{1'b0}};
            i2c_rd_id_r   <= {IC_ID_WIDTH{1'b0}};
            i2c_rd_adr_r  <= 3'b0;
            i2c_rd_dat_r  <= 8'b0;
        end else begin
            case (fsm_rd)
                I2C_RD_IDLE: begin
                    m05_rvalid_r <= 1'b0;
                    if (m05_arvalid && fsm_wr == I2C_WR_IDLE) begin
                        m05_arready_r <= 1'b1;
                        i2c_rd_id_r   <= m05_arid;
                        i2c_rd_adr_r  <= m05_araddr[4:2];
                        fsm_rd        <= I2C_RD_SETUP;
                    end else begin
                        m05_arready_r <= 1'b0;
                    end
                end

                I2C_RD_SETUP: begin
                    m05_arready_r <= 1'b0;
                    fsm_rd        <= I2C_RD_WAIT;
                end

                I2C_RD_WAIT: begin
                    if (wb_ack) begin
                        i2c_rd_dat_r <= wb_dat_rd;
                        m05_rvalid_r <= 1'b1;
                        m05_rdata_r  <= {24'h000000, wb_dat_rd};
                        m05_rresp_r  <= 2'b00;
                        m05_rid_r    <= i2c_rd_id_r;
                        fsm_rd       <= I2C_RD_RESP;
                    end
                end

                I2C_RD_RESP: begin
                    if (m05_rready) begin
                        m05_rvalid_r <= 1'b0;
                        fsm_rd       <= I2C_RD_IDLE;
                    end
                end

                default: fsm_rd <= I2C_RD_IDLE;
            endcase
        end
    end

    assign wb_adr    = (fsm_wr == I2C_WR_WAIT) ? i2c_wr_adr_r : i2c_rd_adr_r;
    assign wb_dat_wr = i2c_wr_dat_r;
    assign wb_we     = (fsm_wr == I2C_WR_WAIT);
    assign wb_stb    = (fsm_wr == I2C_WR_WAIT) || (fsm_rd == I2C_RD_WAIT);
    assign wb_cyc    = (fsm_wr == I2C_WR_WAIT) || (fsm_rd == I2C_RD_WAIT);

    wire scl_pad_i, scl_pad_o, scl_padoen_o;
    wire sda_pad_i, sda_pad_o, sda_padoen_o;

    assign scl_pad_i  = i2c_scl_io;
    assign i2c_scl_io = scl_padoen_o ? 1'bz : scl_pad_o;
    assign sda_pad_i  = i2c_sda_io;
    assign i2c_sda_io = sda_padoen_o ? 1'bz : sda_pad_o;

    // NOTE: ARST_LVL=1'b0 means arst_i is active-low asynchronous reset.
    // arst_n_i2c = rst_n (active-low). So rst_i = rst_n ^ 0 = rst_n.
    // rst_i=0 (reset active) when rst_n=0 (during reset). Correct.
    i2c_master_top #(
        .ARST_LVL(1'b0)
    ) i2c_inst (
        .wb_clk_i       (wb_clk),
        .wb_rst_i       (wb_rst),
        .arst_i         (arst_n_i2c),
        .wb_adr_i       (wb_adr),
        .wb_dat_i       (wb_dat_wr),
        .wb_dat_o       (wb_dat_rd),
        .wb_we_i        (wb_we),
        .wb_stb_i       (wb_stb),
        .wb_cyc_i       (wb_cyc),
        .wb_ack_o       (wb_ack),
        .wb_inta_o      (i2c_interrupt_o),
        .scl_pad_i      (scl_pad_i),
        .scl_pad_o      (scl_pad_o),
        .scl_padoen_o   (scl_padoen_o),
        .sda_pad_i      (sda_pad_i),
        .sda_pad_o      (sda_pad_o),
        .sda_padoen_o   (sda_padoen_o)
    );

    // ========================================================================
    // M06 Slave: PWM (0x4000_3000)
    // ========================================================================
    reg [IC_ID_WIDTH-1:0] pwm_bid_r;
    reg [IC_ID_WIDTH-1:0] pwm_rid_r;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_bid_r <= {IC_ID_WIDTH{1'b0}};
            pwm_rid_r <= {IC_ID_WIDTH{1'b0}};
        end else begin
            if (m06_awvalid && m06_awready)
                pwm_bid_r <= m06_awid;
            if (m06_arvalid && m06_arready)
                pwm_rid_r <= m06_arid;
        end
    end
    assign m06_bid = pwm_bid_r;
    assign m06_rid = pwm_rid_r;

    myip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) pwm_inst (
        .PWM_OUT        (pwm_out_o),
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr (m06_awaddr[3:0]),
        .s00_axi_awprot (m06_awprot),
        .s00_axi_awvalid(m06_awvalid),
        .s00_axi_awready(m06_awready),
        .s00_axi_wdata  (m06_wdata),
        .s00_axi_wstrb  (m06_wstrb),
        .s00_axi_wvalid (m06_wvalid),
        .s00_axi_wready (m06_wready),
        .s00_axi_bresp  (m06_bresp),
        .s00_axi_bvalid (m06_bvalid),
        .s00_axi_bready (m06_bready),
        .s00_axi_araddr (m06_araddr[3:0]),
        .s00_axi_arprot (m06_arprot),
        .s00_axi_arvalid(m06_arvalid),
        .s00_axi_arready(m06_arready),
        .s00_axi_rdata  (m06_rdata),
        .s00_axi_rresp  (m06_rresp),
        .s00_axi_rvalid (m06_rvalid),
        .s00_axi_rready (m06_rready)
    );
    assign m06_rlast = 1'b1;

endmodule
`default_nettype wire
