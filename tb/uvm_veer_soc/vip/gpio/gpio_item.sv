// ============================================================================
// File: gpio_item.sv
// Description: GPIO VIP Sequence Item
// ============================================================================

`ifndef GPIO_ITEM_SV
`define GPIO_ITEM_SV

class gpio_item extends uvm_sequence_item;

  bit [31:0]        gpio_in;
  rand bit [31:0]   gpio_out;
  rand bit [31:0]   gpio_oe;
  rand int unsigned delay;

  `uvm_object_utils_begin(gpio_item)
    `uvm_field_int(gpio_in,  UVM_ALL_ON)
    `uvm_field_int(gpio_out, UVM_ALL_ON)
    `uvm_field_int(gpio_oe,  UVM_ALL_ON)
    `uvm_field_int(delay,    UVM_DEFAULT | UVM_NOCOMPARE)
  `uvm_object_utils_end

  constraint c_delay {
    delay inside {[0:10]};
  }

  function new(string name = "gpio_item");
    super.new(name);
    gpio_in  = 32'h0;
    gpio_out = 32'h0;
    gpio_oe  = 32'h0;
    delay    = 0;
  endfunction

  virtual function string convert2string();
    return $sformatf("gpio_item: in=0x%08x out=0x%08x oe=0x%08x", gpio_in, gpio_out, gpio_oe);
  endfunction

endclass

`endif // GPIO_ITEM_SV
