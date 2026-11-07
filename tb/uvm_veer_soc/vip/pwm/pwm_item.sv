// ============================================================================
// File: pwm_item.sv
// Description: PWM VIP Sequence Item
// ============================================================================

`ifndef PWM_ITEM_SV
`define PWM_ITEM_SV

class pwm_item extends uvm_sequence_item;

  bit pwm_out_o;

  int unsigned period_cycles;
  int unsigned high_cycles;
  int unsigned low_cycles;
  real         duty_cycle_pct;
  bit          enabled;

  `uvm_object_utils_begin(pwm_item)
    `uvm_field_int(pwm_out_o,      UVM_ALL_ON)
    `uvm_field_int(period_cycles,  UVM_ALL_ON)
    `uvm_field_int(high_cycles,    UVM_ALL_ON)
    `uvm_field_int(low_cycles,     UVM_ALL_ON)
    `uvm_field_real(duty_cycle_pct, UVM_ALL_ON)
    `uvm_field_int(enabled,        UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pwm_item");
    super.new(name);
    pwm_out_o      = 1'b0;
    period_cycles  = 0;
    high_cycles    = 0;
    low_cycles     = 0;
    duty_cycle_pct = 0.0;
    enabled        = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("pwm_item: period=%0d cycles, high=%0d, low=%0d, duty=%.2f%%, en=%0b",
                     period_cycles, high_cycles, low_cycles, duty_cycle_pct, enabled);
  endfunction

endclass

`endif // PWM_ITEM_SV
