// ============================================================================
// File: spi_sequence.sv
// Description: SPI VIP Sequences (Single, Multi-byte, Full-Duplex Transfer)
// ============================================================================

`ifndef SPI_SEQUENCE_SV
`define SPI_SEQUENCE_SV

class spi_base_sequence extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_base_sequence)

  function new(string name = "spi_base_sequence");
    super.new(name);
  endfunction

  task send_spi_item(bit [7:0] miso_val);
    `uvm_create(req)
    req.miso_data = miso_val;
    `uvm_send(req)
  endtask
endclass

// Scenario: Single Transfer Response
class spi_single_transfer_seq extends spi_base_sequence;
  `uvm_object_utils(spi_single_transfer_seq)
  function new(string name = "spi_single_transfer_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing SPI Single Transfer response", UVM_HIGH)
    send_spi_item(8'hA5);
  endtask
endclass

// Scenario: Full-Duplex Multi-Transfer
class spi_multi_transfer_seq extends spi_base_sequence;
  `uvm_object_utils(spi_multi_transfer_seq)
  function new(string name = "spi_multi_transfer_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing SPI Full-Duplex Multi-Transfer", UVM_HIGH)
    send_spi_item(8'h5A);
    send_spi_item(8'hC3);
    send_spi_item(8'h3C);
  endtask
endclass

// Scenario: Full SPI Test
class spi_full_test_seq extends spi_base_sequence;
  `uvm_object_utils(spi_full_test_seq)
  function new(string name = "spi_full_test_seq"); super.new(name); endfunction

  virtual task body();
    spi_single_transfer_seq s_seq;
    spi_multi_transfer_seq  m_seq;
    `uvm_do(s_seq)
    `uvm_do(m_seq)
  endtask
endclass

`endif // SPI_SEQUENCE_SV
