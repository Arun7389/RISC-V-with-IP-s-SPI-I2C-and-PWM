// ============================================================================
// File: uart_item.sv
// Description: UART VIP Sequence Item
// ============================================================================

`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

  // Original compatibility signals
  bit uart_tx_o;
  rand bit uart_rx_i;

  // Protocol-level fields
  rand bit [7:0] data;
  bit [7:0]      rx_data;
  bit            is_tx;
  bit            parity_err;
  bit            frame_err;

  `uvm_object_utils_begin(uart_item)
    `uvm_field_int(uart_tx_o,  UVM_DEFAULT)
    `uvm_field_int(uart_rx_i,  UVM_DEFAULT)
    `uvm_field_int(data,       UVM_ALL_ON)
    `uvm_field_int(rx_data,    UVM_ALL_ON)
    `uvm_field_int(is_tx,      UVM_DEFAULT)
    `uvm_field_int(parity_err, UVM_DEFAULT)
    `uvm_field_int(frame_err,  UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "uart_item");
    super.new(name);
    uart_tx_o  = 1'b1;
    uart_rx_i  = 1'b1;
    data       = 8'h00;
    rx_data    = 8'h00;
    is_tx      = 1'b0;
    parity_err = 1'b0;
    frame_err  = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("uart_item: data=0x%02x ('%c') rx_data=0x%02x frame_err=%0b",
                     data, (data >= 32 && data <= 126) ? data : ".", rx_data, frame_err);
  endfunction

endclass

`endif // UART_ITEM_SV
