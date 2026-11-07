`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// Module: axi_mem_slave
// Description:
//   Synchronous 32-bit AXI4 Memory Slave with byte-level write strobes,
//   burst support (FIXED / INCR), read-after-write consistency,
//   and hex file preload support ($readmemh).
//   Configurable capacity (default 64 KB = 65,536 bytes = 16,384 words of 32-bit).
// ============================================================================

module axi_mem_slave #(
    parameter DATA_WIDTH      = 32,
    parameter ADDR_WIDTH      = 32,
    parameter STRB_WIDTH      = DATA_WIDTH / 8,
    parameter ID_WIDTH        = 8,
    parameter MEM_SIZE_BYTES  = 65536,          // 64 KB
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = 32'h0000_0000,
    parameter INIT_FILE       = "",
    parameter PLUSARG_NAME    = ""              // e.g. "IMEM_HEX" or "DMEM_HEX"
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ------------------------------------------------------------------------
    // AXI4 Write Address Channel
    // ------------------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awlock,
    input  wire [3:0]               s_axi_awcache,
    input  wire [2:0]               s_axi_awprot,
    input  wire [3:0]               s_axi_awqos,
    input  wire [3:0]               s_axi_awregion,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,

    // ------------------------------------------------------------------------
    // AXI4 Write Data Channel
    // ------------------------------------------------------------------------
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,

    // ------------------------------------------------------------------------
    // AXI4 Write Response Channel
    // ------------------------------------------------------------------------
    output reg  [ID_WIDTH-1:0]      s_axi_bid,
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,

    // ------------------------------------------------------------------------
    // AXI4 Read Address Channel
    // ------------------------------------------------------------------------
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arlock,
    input  wire [3:0]               s_axi_arcache,
    input  wire [2:0]               s_axi_arprot,
    input  wire [3:0]               s_axi_arqos,
    input  wire [3:0]               s_axi_arregion,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,

    // ------------------------------------------------------------------------
    // AXI4 Read Data Channel
    // ------------------------------------------------------------------------
    output reg  [ID_WIDTH-1:0]      s_axi_rid,
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rlast,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready
);

    localparam NUM_WORDS = MEM_SIZE_BYTES / (DATA_WIDTH / 8);
    localparam ADDR_MASK = MEM_SIZE_BYTES - 1;

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:NUM_WORDS-1];

    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < NUM_WORDS; i = i + 1) begin
            mem[i] = {DATA_WIDTH{1'b0}};
        end

        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // Runtime plusarg check (e.g. +IMEM_HEX=firmware.hex)
    initial begin
        string filename;
        if (PLUSARG_NAME != "") begin
            if ($value$plusargs({PLUSARG_NAME, "=%s"}, filename)) begin
                $display("[axi_mem_slave] Loading hex file '%s' into memory (BASE_ADDR=0x%08x)...", filename, BASE_ADDR);
                $readmemh(filename, mem);
            end
        end
    end

    // ------------------------------------------------------------------------
    // Write State Machine
    // ------------------------------------------------------------------------
    localparam WR_IDLE = 2'd0;
    localparam WR_DATA = 2'd1;
    localparam WR_RESP = 2'd2;

    reg [1:0]            wr_state;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [ID_WIDTH-1:0]   wr_id;
    reg [7:0]            wr_len;
    reg [7:0]            wr_cnt;
    reg [1:0]            wr_burst;

    wire [ADDR_WIDTH-1:0] wr_offset = (wr_addr - BASE_ADDR) & ADDR_MASK;
    wire [ADDR_WIDTH-3:0] wr_word_idx = wr_offset[ADDR_WIDTH-1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state      <= WR_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            wr_addr       <= {ADDR_WIDTH{1'b0}};
            wr_id         <= {ID_WIDTH{1'b0}};
            wr_len        <= 8'd0;
            wr_cnt        <= 8'd0;
            wr_burst      <= 2'd0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b0;
                    if (s_axi_awvalid && s_axi_awready) begin
                        wr_addr       <= s_axi_awaddr;
                        wr_id         <= s_axi_awid;
                        wr_len        <= s_axi_awlen;
                        wr_cnt        <= 8'd0;
                        wr_burst      <= s_axi_awburst;
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b1;
                        wr_state      <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    s_axi_wready <= 1'b1;
                    if (s_axi_wvalid && s_axi_wready) begin
                        // Byte-strobe write
                        if (wr_word_idx < NUM_WORDS) begin
                            if (s_axi_wstrb[0]) mem[wr_word_idx][ 7: 0] <= s_axi_wdata[ 7: 0];
                            if (s_axi_wstrb[1]) mem[wr_word_idx][15: 8] <= s_axi_wdata[15: 8];
                            if (s_axi_wstrb[2]) mem[wr_word_idx][23:16] <= s_axi_wdata[23:16];
                            if (s_axi_wstrb[3]) mem[wr_word_idx][31:24] <= s_axi_wdata[31:24];
                        end

                        if (wr_burst == 2'b01) begin // INCR
                            wr_addr <= wr_addr + 4;
                        end

                        wr_cnt <= wr_cnt + 1'b1;

                        if (s_axi_wlast || (wr_cnt == wr_len)) begin
                            s_axi_wready <= 1'b0;
                            s_axi_bvalid <= 1'b1;
                            s_axi_bresp  <= 2'b00; // OKAY
                            s_axi_bid    <= wr_id;
                            wr_state     <= WR_RESP;
                        end
                    end
                end

                WR_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        wr_state      <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Read State Machine
    // ------------------------------------------------------------------------
    localparam RD_IDLE = 2'd0;
    localparam RD_DATA = 2'd1;

    reg [1:0]            rd_state;
    reg [ADDR_WIDTH-1:0] rd_addr;
    reg [ID_WIDTH-1:0]   rd_id;
    reg [7:0]            rd_len;
    reg [7:0]            rd_cnt;
    reg [1:0]            rd_burst;

    wire [ADDR_WIDTH-1:0] rd_offset = (rd_addr - BASE_ADDR) & ADDR_MASK;
    wire [ADDR_WIDTH-3:0] rd_word_idx = rd_offset[ADDR_WIDTH-1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rlast   <= 1'b0;
            rd_addr       <= {ADDR_WIDTH{1'b0}};
            rd_id         <= {ID_WIDTH{1'b0}};
            rd_len        <= 8'd0;
            rd_cnt        <= 8'd0;
            rd_burst      <= 2'd0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    s_axi_rlast   <= 1'b0;
                    if (s_axi_arvalid && s_axi_arready) begin
                        rd_addr       <= s_axi_araddr;
                        rd_id         <= s_axi_arid;
                        rd_len        <= s_axi_arlen;
                        rd_cnt        <= 8'd0;
                        rd_burst      <= s_axi_arburst;
                        s_axi_arready <= 1'b0;

                        // First beat read
                        s_axi_rvalid <= 1'b1;
                        s_axi_rid    <= s_axi_arid;
                        s_axi_rresp  <= 2'b00; // OKAY
                        s_axi_rlast  <= (s_axi_arlen == 8'd0);
                        
                        // Read with write forwarding
                        if (wr_state == WR_DATA && s_axi_wvalid && s_axi_wready && 
                            (((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2) == wr_word_idx) begin
                            s_axi_rdata <= {
                                s_axi_wstrb[3] ? s_axi_wdata[31:24] : mem[((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2][31:24],
                                s_axi_wstrb[2] ? s_axi_wdata[23:16] : mem[((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2][23:16],
                                s_axi_wstrb[1] ? s_axi_wdata[15: 8] : mem[((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2][15: 8],
                                s_axi_wstrb[0] ? s_axi_wdata[ 7: 0] : mem[((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2][ 7: 0]
                            };
                        end else if ((((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2) < NUM_WORDS) begin
                            s_axi_rdata <= mem[((s_axi_araddr - BASE_ADDR) & ADDR_MASK) >> 2];
                        end else begin
                            s_axi_rdata <= {DATA_WIDTH{1'b0}};
                        end

                        if (s_axi_arburst == 2'b01) begin
                            rd_addr <= s_axi_araddr + 4;
                        end else begin
                            rd_addr <= s_axi_araddr;
                        end

                        rd_cnt   <= 8'd1;
                        rd_state <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast) begin
                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;
                            s_axi_arready <= 1'b1;
                            rd_state      <= RD_IDLE;
                        end else begin
                            // Next beat
                            s_axi_rvalid <= 1'b1;
                            s_axi_rid    <= rd_id;
                            s_axi_rresp  <= 2'b00;
                            s_axi_rlast  <= (rd_cnt == rd_len);

                            if (rd_word_idx < NUM_WORDS) begin
                                s_axi_rdata <= mem[rd_word_idx];
                            end else begin
                                s_axi_rdata <= {DATA_WIDTH{1'b0}};
                            end

                            if (rd_burst == 2'b01) begin
                                rd_addr <= rd_addr + 4;
                            end

                            rd_cnt <= rd_cnt + 1'b1;
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Testbench Backdoor Access Functions
    // ------------------------------------------------------------------------
    function [DATA_WIDTH-1:0] read_word(input [ADDR_WIDTH-1:0] byte_addr);
        reg [ADDR_WIDTH-1:0] offset;
        reg [ADDR_WIDTH-3:0] idx;
        begin
            offset = (byte_addr - BASE_ADDR) & ADDR_MASK;
            idx    = offset[ADDR_WIDTH-1:2];
            if (idx < NUM_WORDS) begin
                read_word = mem[idx];
            end else begin
                read_word = {DATA_WIDTH{1'b0}};
            end
        end
    endfunction

    task write_word(input [ADDR_WIDTH-1:0] byte_addr, input [DATA_WIDTH-1:0] data);
        reg [ADDR_WIDTH-1:0] offset;
        reg [ADDR_WIDTH-3:0] idx;
        begin
            offset = (byte_addr - BASE_ADDR) & ADDR_MASK;
            idx    = offset[ADDR_WIDTH-1:2];
            if (idx < NUM_WORDS) begin
                mem[idx] = data;
            end
        end
    endtask

endmodule
`default_nettype wire
