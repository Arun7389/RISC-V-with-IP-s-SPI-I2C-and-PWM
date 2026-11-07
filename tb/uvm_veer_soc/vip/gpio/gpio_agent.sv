// ============================================================================
// File: gpio_agent.sv
// Description: GPIO VIP Agent
// ============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;
  gpio_driver    drv;
  gpio_monitor   mon;
  gpio_sequencer seqr;
  gpio_coverage  cov;

  `uvm_component_utils(gpio_agent)

  function new(string name = "gpio_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = gpio_monitor::type_id::create("mon", this);
    cov = gpio_coverage::type_id::create("cov", this);

    if (get_is_active() == UVM_ACTIVE) begin
      drv  = gpio_driver::type_id::create("drv", this);
      seqr = gpio_sequencer::type_id::create("seqr", this);
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

`endif // GPIO_AGENT_SV
