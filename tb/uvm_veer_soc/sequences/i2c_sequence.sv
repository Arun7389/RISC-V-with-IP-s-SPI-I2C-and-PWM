// ============================================================================
// File: i2c_sequence.sv
// Description: I2C VIP Sequences (ACK/NACK, Single/Multi Byte Read/Write)
// ============================================================================

`ifndef I2C_SEQUENCE_SV
`define I2C_SEQUENCE_SV

class i2c_base_sequence extends uvm_sequence #(i2c_item);
  `uvm_object_utils(i2c_base_sequence)

  function new(string name = "i2c_base_sequence");
    super.new(name);
  endfunction

  task send_i2c_item(bit [6:0] address, bit is_read, bit [7:0] byte_val, bit ack_val);
    `uvm_create(req)
    req.addr = address;
    req.r_w  = is_read;
    req.data = byte_val;
    req.ack  = ack_val;
    `uvm_send(req)
  endtask
endclass

// Scenario: Standard Slave ACK Response
class i2c_slave_ack_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_slave_ack_seq)
  function new(string name = "i2c_slave_ack_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing I2C Slave ACK sequence", UVM_HIGH)
    send_i2c_item(7'h50, 1'b0, 8'hA5, 1'b0);
  endtask
endclass

// Scenario: Slave NACK Response
class i2c_slave_nack_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_slave_nack_seq)
  function new(string name = "i2c_slave_nack_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing I2C Slave NACK sequence", UVM_HIGH)
    send_i2c_item(7'h51, 1'b0, 8'hFF, 1'b1); // Address mismatch -> NACK
  endtask
endclass

// Scenario: Multi-byte Transaction
class i2c_multi_byte_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_multi_byte_seq)
  function new(string name = "i2c_multi_byte_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing I2C Multi-byte sequence", UVM_HIGH)
    send_i2c_item(7'h50, 1'b0, 8'h01, 1'b0);
    send_i2c_item(7'h50, 1'b0, 8'h02, 1'b0);
    send_i2c_item(7'h50, 1'b0, 8'h03, 1'b0);
  endtask
endclass

// Scenario: Comprehensive I2C Test
class i2c_full_test_seq extends i2c_base_sequence;
  `uvm_object_utils(i2c_full_test_seq)
  function new(string name = "i2c_full_test_seq"); super.new(name); endfunction

  virtual task body();
    i2c_slave_ack_seq  ack_seq;
    i2c_multi_byte_seq multi_seq;
    `uvm_do(ack_seq)
    `uvm_do(multi_seq)
  endtask
endclass

`endif // I2C_SEQUENCE_SV
