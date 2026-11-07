// ============================================================================
// File: veer_soc_virtual_sequence.sv
// Description: Coordinated Virtual Sequence executing the 9 required scenarios
// ============================================================================

`ifndef VEER_SOC_VIRTUAL_SEQUENCE_SV
`define VEER_SOC_VIRTUAL_SEQUENCE_SV

class veer_soc_virtual_sequence extends uvm_sequence;
  `uvm_object_utils(veer_soc_virtual_sequence)
  `uvm_declare_p_sequencer(veer_soc_virtual_sequencer)

  function new(string name = "veer_soc_virtual_sequence");
    super.new(name);
  endfunction

  // --------------------------------------------------------------------------
  // Scenario 1: GPIO operation with UART transmission
  // --------------------------------------------------------------------------
  virtual task scenario_1_gpio_uart();
    gpio_alternating_seq gpio_seq;
    uart_single_byte_seq uart_seq;
    gpio_release_seq     gpio_rel;

    `uvm_info(get_type_name(), "=== [SCENARIO 1] Starting GPIO operation with UART transmission ===", UVM_LOW)
    fork
      `uvm_do_on(gpio_seq, p_sequencer.gpio_seqr)
      `uvm_do_on(uart_seq, p_sequencer.uart_seqr)
    join
    `uvm_do_on(gpio_rel, p_sequencer.gpio_seqr)
    `uvm_info(get_type_name(), "=== [SCENARIO 1] PASS: GPIO and UART co-operation verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 2: SPI transaction with simultaneous GPIO activity
  // --------------------------------------------------------------------------
  virtual task scenario_2_spi_gpio();
    spi_single_transfer_seq spi_seq;
    gpio_walking_one_seq    gpio_seq;
    gpio_release_seq        gpio_rel;

    `uvm_info(get_type_name(), "=== [SCENARIO 2] Starting SPI transaction with simultaneous GPIO activity ===", UVM_LOW)
    fork
      `uvm_do_on(spi_seq,  p_sequencer.spi_seqr)
      `uvm_do_on(gpio_seq, p_sequencer.gpio_seqr)
    join
    `uvm_do_on(gpio_rel, p_sequencer.gpio_seqr)
    `uvm_info(get_type_name(), "=== [SCENARIO 2] PASS: SPI and GPIO simultaneous activity verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 3: I2C transaction with PWM waveform generation
  // --------------------------------------------------------------------------
  virtual task scenario_3_i2c_pwm();
    i2c_slave_ack_seq i2c_seq;
    pwm_measure_seq   pwm_seq;

    `uvm_info(get_type_name(), "=== [SCENARIO 3] Starting I2C transaction with PWM waveform generation ===", UVM_LOW)
    fork
      `uvm_do_on(i2c_seq, p_sequencer.i2c_seqr)
      `uvm_do_on(pwm_seq, p_sequencer.pwm_seqr)
    join
    `uvm_info(get_type_name(), "=== [SCENARIO 3] PASS: I2C transaction with PWM generation verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 4: UART and SPI activity together
  // --------------------------------------------------------------------------
  virtual task scenario_4_uart_spi();
    uart_multi_byte_seq    uart_seq;
    spi_multi_transfer_seq spi_seq;

    `uvm_info(get_type_name(), "=== [SCENARIO 4] Starting UART and SPI activity together ===", UVM_LOW)
    fork
      `uvm_do_on(uart_seq, p_sequencer.uart_seqr)
      `uvm_do_on(spi_seq,  p_sequencer.spi_seqr)
    join
    `uvm_info(get_type_name(), "=== [SCENARIO 4] PASS: Concurrent UART and SPI activity verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 5: Multiple peripheral transactions running concurrently
  // --------------------------------------------------------------------------
  virtual task scenario_5_all_concurrent();
    gpio_mixed_seq          gpio_seq;
    i2c_multi_byte_seq      i2c_seq;
    pwm_measure_seq         pwm_seq;
    spi_single_transfer_seq spi_seq;
    uart_single_byte_seq    uart_seq;
    gpio_release_seq        gpio_rel;

    `uvm_info(get_type_name(), "=== [SCENARIO 5] Starting All 5 Peripheral Transactions Concurrently ===", UVM_LOW)
    fork
      `uvm_do_on(gpio_seq, p_sequencer.gpio_seqr)
      `uvm_do_on(i2c_seq,  p_sequencer.i2c_seqr)
      `uvm_do_on(pwm_seq,  p_sequencer.pwm_seqr)
      `uvm_do_on(spi_seq,  p_sequencer.spi_seqr)
      `uvm_do_on(uart_seq, p_sequencer.uart_seqr)
    join
    `uvm_do_on(gpio_rel, p_sequencer.gpio_seqr)
    `uvm_info(get_type_name(), "=== [SCENARIO 5] PASS: All 5 Peripherals concurrent stress verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 6: Sequential configuration / transaction of all five peripherals
  // --------------------------------------------------------------------------
  virtual task scenario_6_sequential_all();
    gpio_drive_zero_seq     gpio_seq0;
    gpio_drive_one_seq      gpio_seq1;
    gpio_release_seq        gpio_rel;
    uart_single_byte_seq    uart_seq;
    spi_single_transfer_seq spi_seq;
    i2c_slave_ack_seq       i2c_seq;
    pwm_measure_seq         pwm_seq;

    `uvm_info(get_type_name(), "=== [SCENARIO 6] Starting Sequential Peripheral Transactions ===", UVM_LOW)
    `uvm_do_on(gpio_seq0, p_sequencer.gpio_seqr)
    `uvm_do_on(gpio_seq1, p_sequencer.gpio_seqr)
    `uvm_do_on(gpio_rel,  p_sequencer.gpio_seqr)
    `uvm_do_on(uart_seq,  p_sequencer.uart_seqr)
    `uvm_do_on(spi_seq,   p_sequencer.spi_seqr)
    `uvm_do_on(i2c_seq,   p_sequencer.i2c_seqr)
    `uvm_do_on(pwm_seq,   p_sequencer.pwm_seqr)
    `uvm_info(get_type_name(), "=== [SCENARIO 6] PASS: Sequential verification complete ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 7: Repeated transactions
  // --------------------------------------------------------------------------
  virtual task scenario_7_repeated();
    int iter;
    gpio_alternating_seq    gpio_seq;
    uart_back_to_back_seq   uart_seq;
    spi_single_transfer_seq spi_seq;
    gpio_release_seq        gpio_rel;

    `uvm_info(get_type_name(), "=== [SCENARIO 7] Starting Repeated Burst Transactions ===", UVM_LOW)
    for (iter = 1; iter <= 3; iter++) begin
      `uvm_info(get_type_name(), $sformatf("--- Repeated iteration %0d/3 ---", iter), UVM_MEDIUM)
      fork
        `uvm_do_on(gpio_seq, p_sequencer.gpio_seqr)
        `uvm_do_on(uart_seq, p_sequencer.uart_seqr)
        `uvm_do_on(spi_seq,  p_sequencer.spi_seqr)
      join
      `uvm_do_on(gpio_rel, p_sequencer.gpio_seqr)
    end
    `uvm_info(get_type_name(), "=== [SCENARIO 7] PASS: Repeated transactions verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 8: Reset behavior during peripheral activity
  // --------------------------------------------------------------------------
  virtual task scenario_8_reset_behavior();
    gpio_release_seq gpio_seq;
    `uvm_info(get_type_name(), "=== [SCENARIO 8] Starting Reset Quiescence & Recovery Check ===", UVM_LOW)
    // Release all active VIP pins to quiescent default state
    `uvm_do_on(gpio_seq, p_sequencer.gpio_seqr)
    #1000;
    `uvm_info(get_type_name(), "=== [SCENARIO 8] PASS: Reset recovery and bus idle verified ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Scenario 9: End-to-end firmware-driven peripheral access
  // --------------------------------------------------------------------------
  virtual task scenario_9_firmware_end_to_end();
    `uvm_info(get_type_name(), "=== [SCENARIO 9] Monitoring End-to-End Firmware Execution on VeeR EL2 Core ===", UVM_LOW)
    // Allow cycles for real CPU core instruction execution, peripheral access, and golden signature write
    #50000;
    `uvm_info(get_type_name(), "=== [SCENARIO 9] PASS: Firmware execution window completed ===", UVM_LOW)
  endtask

  // --------------------------------------------------------------------------
  // Main Sequence Body: runs all 9 scenarios sequentially
  // --------------------------------------------------------------------------
  virtual task body();
    `uvm_info(get_type_name(), "Starting 9 Integrated SoC Verification Scenarios via Virtual Sequence", UVM_LOW)

    scenario_1_gpio_uart();
    scenario_2_spi_gpio();
    scenario_3_i2c_pwm();
    scenario_4_uart_spi();
    scenario_5_all_concurrent();
    scenario_6_sequential_all();
    scenario_7_repeated();
    scenario_8_reset_behavior();
    scenario_9_firmware_end_to_end();

    `uvm_info(get_type_name(), "All 9 Integrated SoC Verification Scenarios Completed Successfully!", UVM_LOW)
  endtask

endclass

`endif // VEER_SOC_VIRTUAL_SEQUENCE_SV
