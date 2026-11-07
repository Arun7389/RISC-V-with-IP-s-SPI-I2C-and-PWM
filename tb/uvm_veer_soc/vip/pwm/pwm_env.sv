// ============================================================================
// File: pwm_env.sv
// Description: PWM VIP Environment
// ============================================================================

`ifndef PWM_ENV_SV
`define PWM_ENV_SV

class pwm_env extends uvm_env;
  pwm_agent      agent;
  pwm_scoreboard sb;

  `uvm_component_utils(pwm_env)

  function new(string name = "pwm_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = pwm_agent::type_id::create("agent", this);
    sb    = pwm_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.item_export);
  endfunction

endclass

`endif // PWM_ENV_SV
