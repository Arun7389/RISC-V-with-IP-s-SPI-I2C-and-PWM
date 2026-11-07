// ============================================================================
// File: i2c_agent.sv
// Description: I2C VIP Agent
// ============================================================================

`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

class i2c_agent extends uvm_agent;
  i2c_driver    drv;
  i2c_monitor   mon;
  i2c_sequencer seqr;
  i2c_coverage  cov;

  `uvm_component_utils(i2c_agent)

  function new(string name = "i2c_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = i2c_monitor::type_id::create("mon", this);
    cov = i2c_coverage::type_id::create("cov", this);

    if (get_is_active() == UVM_ACTIVE) begin
      drv  = i2c_driver::type_id::create("drv", this);
      seqr = i2c_sequencer::type_id::create("seqr", this);
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

`endif // I2C_AGENT_SV
