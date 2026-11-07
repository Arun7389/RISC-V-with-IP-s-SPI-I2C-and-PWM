// ============================================================================
// File: pwm_if.sv
// Description: PWM VIP Interface
// ============================================================================

`ifndef PWM_IF_SV
`define PWM_IF_SV

interface pwm_if;
  logic clk;
  logic rst_n;

  // Signal members matching original specification
  logic pwm_out_o;

endinterface

`endif // PWM_IF_SV
