// ============================================================================
// File: pwm_sequence.sv
// Description: PWM VIP Sequences (Period and Duty Cycle Verification)
// ============================================================================

`ifndef PWM_SEQUENCE_SV
`define PWM_SEQUENCE_SV

class pwm_base_sequence extends uvm_sequence #(pwm_item);
  `uvm_object_utils(pwm_base_sequence)

  function new(string name = "pwm_base_sequence");
    super.new(name);
  endfunction

  task sample_pwm();
    `uvm_create(req)
    `uvm_send(req)
  endtask
endclass

// Scenario: Sample and measure PWM output waveform
class pwm_measure_seq extends pwm_base_sequence;
  `uvm_object_utils(pwm_measure_seq)
  function new(string name = "pwm_measure_seq"); super.new(name); endfunction

  virtual task body();
    int count;
    `uvm_info(get_type_name(), "Executing PWM Measurement Sequence", UVM_HIGH)
    for (count = 0; count < 5; count++) begin
      sample_pwm();
    end
  endtask
endclass

// Scenario: Full PWM Verification Sequence
class pwm_full_test_seq extends pwm_base_sequence;
  `uvm_object_utils(pwm_full_test_seq)
  function new(string name = "pwm_full_test_seq"); super.new(name); endfunction

  virtual task body();
    pwm_measure_seq m_seq;
    `uvm_do(m_seq)
  endtask
endclass

`endif // PWM_SEQUENCE_SV
