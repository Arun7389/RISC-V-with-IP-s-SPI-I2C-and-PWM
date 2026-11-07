// ============================================================================
// File: veer_soc_pkg.sv
// Description: Top-Level UVM Package for VeeR EL2 SoC Integration
// ============================================================================

`ifndef VEER_SOC_PKG_SV
`define VEER_SOC_PKG_SV

package veer_soc_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import all 5 Subsystem VIP Packages
  import gpio_pkg::*;
  import i2c_pkg::*;
  import pwm_pkg::*;
  import spi_pkg::*;
  import uart_pkg::*;

  // Include Sequencers, Sequences, Scoreboard, Environment, and Test
  `include "veer_soc_virtual_sequencer.sv"
  `include "gpio_sequence.sv"
  `include "i2c_sequence.sv"
  `include "pwm_sequence.sv"
  `include "spi_sequence.sv"
  `include "uart_sequence.sv"
  `include "veer_soc_virtual_sequence.sv"
  `include "veer_soc_scoreboard.sv"
  `include "veer_soc_env.sv"
  `include "veer_soc_test.sv"

endpackage

`endif // VEER_SOC_PKG_SV
