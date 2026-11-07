// ============================================================================
// File: spi_pkg.sv
// Description: SPI VIP Package Definition
// ============================================================================

`ifndef SPI_PKG_SV
`define SPI_PKG_SV

package spi_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "spi_item.sv"
  `include "spi_sequencer.sv"
  `include "spi_driver.sv"
  `include "spi_monitor.sv"
  `include "spi_coverage.sv"
  `include "spi_scoreboard.sv"
  `include "spi_agent.sv"
  `include "spi_env.sv"

endpackage

`endif // SPI_PKG_SV
