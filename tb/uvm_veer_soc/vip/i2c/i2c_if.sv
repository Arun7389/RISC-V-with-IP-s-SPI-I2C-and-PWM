// ============================================================================
// File: i2c_if.sv
// Description: I2C VIP Interface with Open-Drain Modeling
// ============================================================================

`ifndef I2C_IF_SV
`define I2C_IF_SV

interface i2c_if;
  logic clk;
  logic rst_n;

  // Signal members matching original specification
  logic i2c_scl_in;
  logic i2c_scl_out;
  logic i2c_scl_oe;
  logic i2c_sda_in;
  logic i2c_sda_out;
  logic i2c_sda_oe;

  // Bidirectional physical wires
  wire  scl;
  wire  sda;

  // VIP driver controls
  logic scl_drv;
  logic scl_en;
  logic sda_drv;
  logic sda_en;

  // Open-drain pin drive: pull to 0 when enabled, release to Z otherwise
  assign scl = scl_en ? scl_drv : 1'bz;
  assign sda = sda_en ? sda_drv : 1'bz;

  assign i2c_scl_in = scl;
  assign i2c_sda_in = sda;

endinterface

`endif // I2C_IF_SV
