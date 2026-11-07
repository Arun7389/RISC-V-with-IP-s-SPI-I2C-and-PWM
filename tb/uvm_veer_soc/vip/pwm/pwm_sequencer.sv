// ============================================================================
// File: pwm_sequencer.sv
// Description: PWM VIP Sequencer
// ============================================================================

`ifndef PWM_SEQUENCER_SV
`define PWM_SEQUENCER_SV

class pwm_sequencer extends uvm_sequencer #(pwm_item);
  `uvm_component_utils(pwm_sequencer)

  function new(string name = "pwm_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif // PWM_SEQUENCER_SV
