// ============================================================================
// File: i2c_pkg.sv
// Description: I2C VIP Package Definition
// ============================================================================

`ifndef I2C_PKG_SV
`define I2C_PKG_SV

package i2c_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "i2c_item.sv"
  `include "i2c_sequencer.sv"
  `include "i2c_driver.sv"
  `include "i2c_monitor.sv"
  `include "i2c_coverage.sv"
  `include "i2c_scoreboard.sv"
  `include "i2c_agent.sv"
  `include "i2c_env.sv"

endpackage

`endif // I2C_PKG_SV
