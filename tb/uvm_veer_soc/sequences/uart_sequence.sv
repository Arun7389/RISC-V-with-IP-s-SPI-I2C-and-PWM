// ============================================================================
// File: uart_sequence.sv
// Description: UART VIP Sequences (Single Byte, Multi-byte, Back-to-Back)
// ============================================================================

`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

class uart_base_sequence extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_base_sequence)

  function new(string name = "uart_base_sequence");
    super.new(name);
  endfunction

  task send_uart_byte(bit [7:0] byte_val);
    `uvm_create(req)
    req.data = byte_val;
    `uvm_send(req)
  endtask
endclass

// Scenario: Single-byte transmission to DUT RX
class uart_single_byte_seq extends uart_base_sequence;
  `uvm_object_utils(uart_single_byte_seq)
  function new(string name = "uart_single_byte_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing UART Single-byte transmission ('K'=0x4B)", UVM_HIGH)
    send_uart_byte(8'h4B);
  endtask
endclass

// Scenario: Multi-byte transmission to DUT RX
class uart_multi_byte_seq extends uart_base_sequence;
  `uvm_object_utils(uart_multi_byte_seq)
  function new(string name = "uart_multi_byte_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing UART Multi-byte transmission (\"VeeR\")", UVM_HIGH)
    send_uart_byte(8'h56); // 'V'
    send_uart_byte(8'h65); // 'e'
    send_uart_byte(8'h65); // 'e'
    send_uart_byte(8'h52); // 'R'
  endtask
endclass

// Scenario: Back-to-back transmission
class uart_back_to_back_seq extends uart_base_sequence;
  `uvm_object_utils(uart_back_to_back_seq)
  function new(string name = "uart_back_to_back_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing UART Back-to-Back transmission", UVM_HIGH)
    send_uart_byte(8'hAA);
    send_uart_byte(8'h55);
    send_uart_byte(8'hC3);
    send_uart_byte(8'h3C);
  endtask
endclass

// Scenario: Comprehensive UART Test
class uart_full_test_seq extends uart_base_sequence;
  `uvm_object_utils(uart_full_test_seq)
  function new(string name = "uart_full_test_seq"); super.new(name); endfunction

  virtual task body();
    uart_single_byte_seq  s_seq;
    uart_multi_byte_seq   m_seq;
    uart_back_to_back_seq b_seq;
    `uvm_do(s_seq)
    `uvm_do(m_seq)
    `uvm_do(b_seq)
  endtask
endclass

`endif // UART_SEQUENCE_SV
