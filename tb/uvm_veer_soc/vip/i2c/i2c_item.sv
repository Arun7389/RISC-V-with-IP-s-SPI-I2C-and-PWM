// ============================================================================
// File: i2c_item.sv
// Description: I2C VIP Sequence Item
// ============================================================================

`ifndef I2C_ITEM_SV
`define I2C_ITEM_SV

class i2c_item extends uvm_sequence_item;

  // Original compatibility signals
  bit i2c_scl_in;
  rand bit i2c_scl_out;
  rand bit i2c_scl_oe;
  bit i2c_sda_in;
  rand bit i2c_sda_out;
  rand bit i2c_sda_oe;

  // Protocol-level fields
  rand bit [6:0] addr;
  rand bit       r_w;       // 0 = write, 1 = read
  rand bit [7:0] data;
  bit [7:0]      payload[$];
  bit            ack;       // 0 = ACK, 1 = NACK
  bit            is_start;
  bit            is_repeated_start;
  bit            is_stop;

  `uvm_object_utils_begin(i2c_item)
    `uvm_field_int(addr,              UVM_ALL_ON)
    `uvm_field_int(r_w,               UVM_ALL_ON)
    `uvm_field_int(data,              UVM_ALL_ON)
    `uvm_field_queue_int(payload,     UVM_ALL_ON)
    `uvm_field_int(ack,               UVM_ALL_ON)
    `uvm_field_int(is_start,          UVM_DEFAULT)
    `uvm_field_int(is_repeated_start, UVM_DEFAULT)
    `uvm_field_int(is_stop,           UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "i2c_item");
    super.new(name);
    addr              = 7'h50;
    r_w               = 1'b0;
    data              = 8'h00;
    ack               = 1'b0;
    is_start          = 1'b0;
    is_repeated_start = 1'b0;
    is_stop           = 1'b0;
  endfunction

  virtual function string convert2string();
    return $sformatf("i2c_item: addr=0x%02x r_w=%0b data=0x%02x ack=%0b (start=%0b rep=%0b stop=%0b)",
                     addr, r_w, data, ack, is_start, is_repeated_start, is_stop);
  endfunction

endclass

`endif // I2C_ITEM_SV
