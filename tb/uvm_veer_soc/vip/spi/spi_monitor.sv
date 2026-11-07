// ============================================================================
// File: spi_monitor.sv
// Description: SPI VIP Protocol Monitor
// ============================================================================

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;
  int unsigned obs_count = 0;

  `uvm_component_utils(spi_monitor)

  function new(string name = "spi_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)) begin
      `uvm_fatal("SPI_MON", "SPI virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    spi_item item;
    int bit_idx;
    bit [7:0] captured_mosi;
    bit [7:0] captured_miso;

    @(posedge vif.rst_n);

    forever begin
      @(negedge vif.spi_cs_n_o);
      captured_mosi = 8'h00;
      captured_miso = 8'h00;

      for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
        @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o or negedge vif.rst_n);
        if (vif.spi_cs_n_o || !vif.rst_n) break;
        captured_mosi[bit_idx] = vif.spi_mosi_o;
        captured_miso[bit_idx] = vif.spi_miso_i;
      end

      if (bit_idx < 0) begin
        obs_count++;
        item = spi_item::type_id::create("item");
        item.mosi_data  = captured_mosi;
        item.miso_data  = captured_miso;
        item.spi_cs_n_o = 1'b0;

        `uvm_info("SPI_MONITOR", $sformatf("[OBS #%0d] Observed SPI Full-Duplex Frame: MOSI=0x%02x, MISO=0x%02x (CS_N Active LOW)",
                  obs_count, item.mosi_data, item.miso_data), UVM_MEDIUM)

        ap.write(item);
      end
    end
  endtask

endclass

`endif // SPI_MONITOR_SV
