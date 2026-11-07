// ============================================================================
// File: i2c_coverage.sv
// Description: I2C VIP Coverage Collector
// ============================================================================

`ifndef I2C_COVERAGE_SV
`define I2C_COVERAGE_SV

class i2c_coverage extends uvm_subscriber #(i2c_item);
  `uvm_component_utils(i2c_coverage)

  i2c_item cov_item;

  covergroup cg_i2c;
    cp_addr: coverpoint cov_item.addr {
      bins slave_50  = {7'h50};
      bins general   = {7'h00};
      bins other     = default;
    }
    cp_rw: coverpoint cov_item.r_w {
      bins write_op = {1'b0};
      bins read_op  = {1'b1};
    }
    cp_ack: coverpoint cov_item.ack {
      bins ack_bin  = {1'b0};
      bins nack_bin = {1'b1};
    }
    cross_op: cross cp_addr, cp_rw, cp_ack;
  endgroup

  function new(string name = "i2c_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_i2c = new();
  endfunction

  virtual function void write(i2c_item t);
    cov_item = t;
    cg_i2c.sample();
  endfunction

endclass

`endif // I2C_COVERAGE_SV
