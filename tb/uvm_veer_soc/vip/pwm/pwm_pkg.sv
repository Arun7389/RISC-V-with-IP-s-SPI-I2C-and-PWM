// ============================================================================
// File: pwm_pkg.sv
// Description: PWM VIP Package Definition
// ============================================================================

`ifndef PWM_PKG_SV
`define PWM_PKG_SV

package pwm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "pwm_item.sv"
  `include "pwm_sequencer.sv"
  `include "pwm_driver.sv"
  `include "pwm_monitor.sv"
  `include "pwm_coverage.sv"
  `include "pwm_scoreboard.sv"
  `include "pwm_agent.sv"
  `include "pwm_env.sv"

endpackage

`endif // PWM_PKG_SV
