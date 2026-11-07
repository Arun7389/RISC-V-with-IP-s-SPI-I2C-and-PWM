// ============================================================================
// File: gpio_coverage.sv
// Description: GPIO VIP Coverage Collector
// ============================================================================

`ifndef GPIO_COVERAGE_SV
`define GPIO_COVERAGE_SV

class gpio_coverage extends uvm_subscriber #(gpio_item);
  `uvm_component_utils(gpio_coverage)

  gpio_item cov_item;

  covergroup cg_gpio;
    cp_in: coverpoint cov_item.gpio_in {
      bins zero         = {32'h0000_0000};
      bins all_ones     = {32'hFFFF_FFFF};
      bins alt_a5       = {32'h0000_00A5, 32'hA5A5_A5A5};
      bins alt_5a       = {32'h0000_005A, 32'h5A5A_5A5A};
      bins walking_ones = {32'h1, 32'h2, 32'h4, 32'h8, 32'h10, 32'h20, 32'h40, 32'h80};
      bins other        = default;
    }
    cp_oe: coverpoint cov_item.gpio_oe {
      bins all_input  = {32'h0000_0000};
      bins all_output = {32'hFFFF_FFFF};
      bins byte0_out  = {32'h0000_00FF};
      bins mixed      = default;
    }
  endgroup

  function new(string name = "gpio_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_gpio = new();
  endfunction

  virtual function void write(gpio_item t);
    cov_item = t;
    cg_gpio.sample();
  endfunction

endclass

`endif // GPIO_COVERAGE_SV
