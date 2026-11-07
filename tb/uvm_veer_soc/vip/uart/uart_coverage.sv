// ============================================================================
// File: uart_coverage.sv
// Description: UART VIP Coverage Collector
// ============================================================================

`ifndef UART_COVERAGE_SV
`define UART_COVERAGE_SV

class uart_coverage extends uvm_subscriber #(uart_item);
  `uvm_component_utils(uart_coverage)

  uart_item cov_item;

  covergroup cg_uart;
    cp_data: coverpoint cov_item.data {
      bins fw_char_V  = {8'h56}; // 'V' transmitted by firmware
      bins ascii_low  = {[8'h30 : 8'h39]}; // '0'-'9'
      bins ascii_up   = {[8'h41 : 8'h5A]}; // 'A'-'Z'
      bins ascii_down = {[8'h61 : 8'h7A]}; // 'a'-'z'
      bins byte_zero  = {8'h00};
      bins byte_ff    = {8'hFF};
      bins other      = default;
    }
    cp_err: coverpoint cov_item.frame_err {
      bins no_err  = {1'b0};
      bins err_bin = {1'b1};
    }
  endgroup

  function new(string name = "uart_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_uart = new();
  endfunction

  virtual function void write(uart_item t);
    cov_item = t;
    cg_uart.sample();
  endfunction

endclass

`endif // UART_COVERAGE_SV
