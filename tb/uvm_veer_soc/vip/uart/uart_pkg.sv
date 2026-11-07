// ============================================================================
// File: uart_pkg.sv
// Description: UART VIP Package Definition
// ============================================================================

`ifndef UART_PKG_SV
`define UART_PKG_SV

package uart_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "uart_item.sv"
  `include "uart_sequencer.sv"
  `include "uart_driver.sv"
  `include "uart_monitor.sv"
  `include "uart_coverage.sv"
  `include "uart_scoreboard.sv"
  `include "uart_agent.sv"
  `include "uart_env.sv"

endpackage

`endif // UART_PKG_SV
