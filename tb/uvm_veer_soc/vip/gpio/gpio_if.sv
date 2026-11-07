// ============================================================================
// File: gpio_if.sv
// Description: GPIO VIP Interface with Clock, Reset, and Tri-state IO modeling
// ============================================================================

`ifndef GPIO_IF_SV
`define GPIO_IF_SV

interface gpio_if;
  logic clk;
  logic rst_n;

  // Signal members matching original specification
  logic [31:0] gpio_in;
  logic [31:0] gpio_out;
  logic [31:0] gpio_oe;

  // Physical bidirectional pad bus
  wire  [31:0] gpio_io_pin;

  // Tri-state driver when VIP output enable is asserted
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : g_pin_drive
      assign gpio_io_pin[i] = gpio_oe[i] ? gpio_out[i] : 1'bz;
    end
  endgenerate

  // VIP input always observes the actual pad state
  assign gpio_in = gpio_io_pin;

endinterface

`endif // GPIO_IF_SV
