// ============================================================================
// File: veer_soc_virtual_sequencer.sv
// Description: Integrated VeeR SoC Virtual Sequencer coordinating all 5 VIPs
// ============================================================================

`ifndef VEER_SOC_VIRTUAL_SEQUENCER_SV
`define VEER_SOC_VIRTUAL_SEQUENCER_SV

class veer_soc_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(veer_soc_virtual_sequencer)

  // Subsystem VIP Sequencer Handles
  gpio_sequencer gpio_seqr;
  i2c_sequencer  i2c_seqr;
  pwm_sequencer  pwm_seqr;
  spi_sequencer  spi_seqr;
  uart_sequencer uart_seqr;

  function new(string name = "veer_soc_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif // VEER_SOC_VIRTUAL_SEQUENCER_SV
