// ============================================================================
// File: spi_agent.sv
// Description: SPI VIP Agent
// ============================================================================

`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;
  spi_driver    drv;
  spi_monitor   mon;
  spi_sequencer seqr;
  spi_coverage  cov;

  `uvm_component_utils(spi_agent)

  function new(string name = "spi_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = spi_monitor::type_id::create("mon", this);
    cov = spi_coverage::type_id::create("cov", this);

    if (get_is_active() == UVM_ACTIVE) begin
      drv  = spi_driver::type_id::create("drv", this);
      seqr = spi_sequencer::type_id::create("seqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(cov.analysis_export);

    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass

`endif // SPI_AGENT_SV
