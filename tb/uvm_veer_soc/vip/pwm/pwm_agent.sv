// ============================================================================
// File: pwm_agent.sv
// Description: PWM VIP Agent
// ============================================================================

`ifndef PWM_AGENT_SV
`define PWM_AGENT_SV

class pwm_agent extends uvm_agent;
  pwm_driver    drv;
  pwm_monitor   mon;
  pwm_sequencer seqr;
  pwm_coverage  cov;

  `uvm_component_utils(pwm_agent)

  function new(string name = "pwm_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = pwm_monitor::type_id::create("mon", this);
    cov = pwm_coverage::type_id::create("cov", this);

    if (get_is_active() == UVM_ACTIVE) begin
      drv  = pwm_driver::type_id::create("drv", this);
      seqr = pwm_sequencer::type_id::create("seqr", this);
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

`endif // PWM_AGENT_SV
