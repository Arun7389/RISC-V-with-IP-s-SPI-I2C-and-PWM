// ============================================================================
// File: i2c_sequencer.sv
// Description: I2C VIP Sequencer
// ============================================================================

`ifndef I2C_SEQUENCER_SV
`define I2C_SEQUENCER_SV

class i2c_sequencer extends uvm_sequencer #(i2c_item);
  `uvm_component_utils(i2c_sequencer)

  function new(string name = "i2c_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif // I2C_SEQUENCER_SV
