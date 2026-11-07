// ============================================================================
// File: pwm_coverage.sv
// Description: PWM VIP Coverage Collector
// ============================================================================

`ifndef PWM_COVERAGE_SV
`define PWM_COVERAGE_SV

class pwm_coverage extends uvm_subscriber #(pwm_item);
  `uvm_component_utils(pwm_coverage)

  pwm_item     cov_item;
  int unsigned duty_int;

  covergroup cg_pwm;
    cp_duty: coverpoint duty_int {
      bins zero     = {0};
      bins duty_50  = {[45 : 55]};
      bins duty_100 = {[95 : 100]};
      bins low_duty = {[1 : 44]};
      bins hi_duty  = {[56 : 94]};
    }
    cp_en: coverpoint cov_item.enabled {
      bins disabled = {1'b0};
      bins enabled  = {1'b1};
    }
  endgroup

  function new(string name = "pwm_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_pwm = new();
  endfunction

  virtual function void write(pwm_item t);
    cov_item = t;
    duty_int = int'(t.duty_cycle_pct);
    cg_pwm.sample();
  endfunction

endclass

`endif // PWM_COVERAGE_SV
