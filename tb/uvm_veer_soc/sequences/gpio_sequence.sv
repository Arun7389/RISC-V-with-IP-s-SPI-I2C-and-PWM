// ============================================================================
// File: gpio_sequence.sv
// Description: GPIO VIP Sequences (Logic 0/1, Alternating, Walking 1/0, Mixed, Release)
// ============================================================================

`ifndef GPIO_SEQUENCE_SV
`define GPIO_SEQUENCE_SV

class gpio_base_sequence extends uvm_sequence #(gpio_item);
  `uvm_object_utils(gpio_base_sequence)

  function new(string name = "gpio_base_sequence");
    super.new(name);
  endfunction

  task send_gpio(bit [31:0] out_val, bit [31:0] oe_val, int unsigned dly = 1);
    `uvm_create(req)
    req.gpio_out = out_val;
    req.gpio_oe  = oe_val;
    req.delay    = dly;
    `uvm_send(req)
  endtask
endclass

// Scenario: Drive logic 0
class gpio_drive_zero_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_drive_zero_seq)
  function new(string name = "gpio_drive_zero_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(),
      "Executing GPIO initial data pattern: 0x00000070", UVM_MEDIUM)

    send_gpio(32'h0000_0070, 32'hFFFF_FFFF, 2);
  endtask
endclass

// Scenario: Drive logic 1
class gpio_drive_one_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_drive_one_seq)
  function new(string name = "gpio_drive_one_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing GPIO Drive Logic 1 scenario", UVM_HIGH)
    send_gpio(32'hFFFF_FFFF, 32'hFFFF_FFFF, 2);
  endtask
endclass

// Scenario: Alternating bit patterns
class gpio_alternating_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_alternating_seq)
  function new(string name = "gpio_alternating_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing GPIO Alternating bit patterns scenario", UVM_HIGH)
    send_gpio(32'hAAAA_0070, 32'hFFFF_FFFF, 2);
    send_gpio(32'h5555_AAAA, 32'hFFFF_FFFF, 2);
  endtask
endclass

// Scenario: Walking-one pattern
class gpio_walking_one_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_walking_one_seq)
  function new(string name = "gpio_walking_one_seq"); super.new(name); endfunction

  virtual task body();
    int i;
    `uvm_info(get_type_name(), "Executing GPIO Walking-one scenario", UVM_HIGH)
    for (i = 0; i < 32; i++) begin
      send_gpio(1 << i, 32'hFFFF_FFFF, 1);
    end
  endtask
endclass

// Scenario: Walking-zero pattern
class gpio_walking_zero_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_walking_zero_seq)
  function new(string name = "gpio_walking_zero_seq"); super.new(name); endfunction

  virtual task body();
    int i;
    `uvm_info(get_type_name(), "Executing GPIO Walking-zero scenario", UVM_HIGH)
    for (i = 0; i < 32; i++) begin
      send_gpio(~(1 << i), 32'hFFFF_FFFF, 1);
    end
  endtask
endclass

// Scenario: Mixed Input/Output Operation
class gpio_mixed_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_mixed_seq)
  function new(string name = "gpio_mixed_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing GPIO Mixed Direction scenario", UVM_HIGH)
    // Lower 16 bits driven by VIP (inputs to DUT), upper 16 bits released for DUT output
    send_gpio(32'h0000_1234, 32'h0000_FFFF, 2);
    send_gpio(32'h0000_5678, 32'h0000_FFFF, 2);
    // Release all pins to High-Z
    send_gpio(32'h0000_0000, 32'h0000_0000, 2);
  endtask
endclass

// Scenario: Release all pins to High-Z (tri-state) so DUT can drive GPIO bus without contention
class gpio_release_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_release_seq)
  function new(string name = "gpio_release_seq"); super.new(name); endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Releasing all GPIO pins to High-Z (tri-state)", UVM_HIGH)
    send_gpio(32'h0000_0000, 32'h0000_0000, 2);
  endtask
endclass

// Comprehensive GPIO test sequence
class gpio_full_test_seq extends gpio_base_sequence;
  `uvm_object_utils(gpio_full_test_seq)
  function new(string name = "gpio_full_test_seq"); super.new(name); endfunction

  virtual task body();
    gpio_drive_zero_seq   seq_0;
    gpio_drive_one_seq    seq_1;
    gpio_alternating_seq  seq_alt;
    gpio_walking_one_seq  seq_w1;
    gpio_walking_zero_seq seq_w0;
    gpio_mixed_seq        seq_mix;
    gpio_release_seq      seq_rel;

    `uvm_do(seq_0)
    `uvm_do(seq_1)
    `uvm_do(seq_alt)
    `uvm_do(seq_w1)
    `uvm_do(seq_w0)
    `uvm_do(seq_mix)
    `uvm_do(seq_rel)
  endtask
endclass

`endif // GPIO_SEQUENCE_SV
