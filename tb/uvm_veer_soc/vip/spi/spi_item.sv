// ============================================================================
// File: spi_item.sv
// Description: SPI VIP Sequence Item
// ============================================================================

`ifndef SPI_ITEM_SV
`define SPI_ITEM_SV

class spi_item extends uvm_sequence_item;

  // Original compatibility signals
  bit spi_clk_o;
  bit spi_cs_n_o;
  bit spi_mosi_o;
  rand bit spi_miso_i;

  // Protocol-level fields
  rand bit [7:0] mosi_data;
  rand bit [7:0] miso_data;
  bit            cpol;
  bit            cpha;

  `uvm_object_utils_begin(spi_item)
    `uvm_field_int(spi_clk_o,  UVM_DEFAULT)
    `uvm_field_int(spi_cs_n_o, UVM_DEFAULT)
    `uvm_field_int(spi_mosi_o, UVM_DEFAULT)
    `uvm_field_int(spi_miso_i, UVM_DEFAULT)
    `uvm_field_int(mosi_data,  UVM_ALL_ON)
    `uvm_field_int(miso_data,  UVM_ALL_ON)
    `uvm_field_int(cpol,       UVM_DEFAULT)
    `uvm_field_int(cpha,       UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "spi_item");
    super.new(name);
    spi_clk_o  = 1'b0;
    spi_cs_n_o = 1'b1;
    spi_mosi_o = 1'b0;
    spi_miso_i = 1'b0;
    mosi_data  = 8'h00;
    miso_data  = 8'hA5;
    cpol       = 1'b0;
    cpha       = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("spi_item: MOSI=0x%02x, MISO=0x%02x (CS_N=%0b)",
                     mosi_data, miso_data, spi_cs_n_o);
  endfunction

endclass

`endif // SPI_ITEM_SV
