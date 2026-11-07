// ============================================================================
// File: spi_if.sv
// Description: SPI VIP Interface
// ============================================================================

`ifndef SPI_IF_SV
`define SPI_IF_SV

interface spi_if;
  logic clk;
  logic rst_n;

  // Signal members matching original specification
  logic spi_clk_o;
  logic spi_cs_n_o;
  logic spi_mosi_o;
  logic spi_miso_i;

endinterface

`endif // SPI_IF_SV
