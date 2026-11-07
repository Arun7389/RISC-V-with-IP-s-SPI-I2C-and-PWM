// ============================================================================
// File: pwm_scoreboard.sv
// Description: PWM VIP Scoreboard
// ============================================================================

`ifndef PWM_SCOREBOARD_SV
`define PWM_SCOREBOARD_SV

class pwm_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(pwm_scoreboard)

  uvm_analysis_imp #(pwm_item, pwm_scoreboard) item_export;

  int unsigned total_measurements;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "pwm_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export        = new("item_export", this);
    total_measurements = 0;
    pass_count         = 0;
    fail_count         = 0;
  endfunction

  virtual function void write(pwm_item item);
    bit check_ok;
    total_measurements++;

    if (item.enabled) begin
      check_ok = (item.period_cycles == 256) &&
                 (item.duty_cycle_pct >= 49.0 && item.duty_cycle_pct <= 51.0);
      if (check_ok) begin
        pass_count++;
        `uvm_info(get_type_name(), $sformatf("PWM check PASS: Period=%0d cycles (exp 256), Duty=%.1f%% (exp 50.0%%)",
                  item.period_cycles, item.duty_cycle_pct), UVM_HIGH)
      end else begin
        fail_count++;
        `uvm_error(get_type_name(), $sformatf("PWM check FAIL: Period=%0d cycles (exp 256), Duty=%.1f%% (exp 50.0%%)",
                   item.period_cycles, item.duty_cycle_pct))
      end
    end else begin
      if (item.duty_cycle_pct == 0.0) begin
        pass_count++;
        `uvm_info(get_type_name(), "PWM check PASS: 0% duty cycle observed prior to enable", UVM_HIGH)
      end else begin
        fail_count++;
        `uvm_error(get_type_name(), $sformatf("PWM check FAIL: Unexpected duty cycle %.1f%% prior to enable", item.duty_cycle_pct))
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("PWM Scoreboard Report: Total=%0d, PASS=%0d, FAIL=%0d",
              total_measurements, pass_count, fail_count), UVM_LOW)
  endfunction

endclass

`endif // PWM_SCOREBOARD_SV
