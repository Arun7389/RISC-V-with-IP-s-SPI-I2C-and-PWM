// ============================================================================
// File: spi_coverage.sv
// Description: SPI VIP Coverage Collector
// ============================================================================

`ifndef SPI_COVERAGE_SV
`define SPI_COVERAGE_SV

class spi_coverage extends uvm_subscriber #(spi_item);
  `uvm_component_utils(spi_coverage)

  spi_item cov_item;

  covergroup cg_spi;
    cp_mosi: coverpoint cov_item.mosi_data {
      bins fw_byte    = {8'h37};
      bins all_zeros  = {8'h00};
      bins all_ones   = {8'hFF};
      bins pattern_a5 = {8'hA5};
      bins pattern_5a = {8'h5A};
      bins other      = default;
    }
    cp_miso: coverpoint cov_item.miso_data {
      bins pattern_a5 = {8'hA5};
      bins pattern_5a = {8'h5A};
      bins other      = default;
    }
    cross_data: cross cp_mosi, cp_miso;
  endgroup

  function new(string name = "spi_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_spi = new();
  endfunction

  virtual function void write(spi_item t);
    cov_item = t;
    cg_spi.sample();
  endfunction

endclass

`endif // SPI_COVERAGE_SV
