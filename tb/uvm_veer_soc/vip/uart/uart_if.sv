// ============================================================================
// File: uart_if.sv
// Description: UART VIP Interface
// ============================================================================

`ifndef UART_IF_SV
`define UART_IF_SV

interface uart_if;
  logic clk;
  logic rst_n;

  // Signal members matching original specification
  logic uart_tx_o;
  logic uart_rx_i;

endinterface

`endif // UART_IF_SV
