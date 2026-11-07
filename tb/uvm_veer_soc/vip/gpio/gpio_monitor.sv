// ============================================================================
// File: gpio_monitor.sv
// Description: GPIO VIP Monitor
// ============================================================================

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;
  virtual gpio_if vif;
  uvm_analysis_port #(gpio_item) ap;
  int unsigned obs_count = 0;

  `uvm_component_utils(gpio_monitor)

  function new(string name = "gpio_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
      `uvm_fatal("GPIO_MON", "GPIO virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    gpio_item item;
    logic [31:0] prev_pin;

    @(posedge vif.rst_n);
    prev_pin = vif.gpio_in;

    forever begin
      @(posedge vif.clk);
      if (vif.gpio_in !== prev_pin) begin
        obs_count++;
        item = gpio_item::type_id::create("item");
        item.gpio_in  = vif.gpio_in;
        item.gpio_out = vif.gpio_out;
        item.gpio_oe  = vif.gpio_oe;
        prev_pin      = vif.gpio_in;

        `uvm_info("GPIO_MONITOR", $sformatf("[OBS #%0d] Observed GPIO Pin Transition: Pin=0x%08x (VIP OE=0x%08x, VIP OUT=0x%08x, Source=%s)",
                  obs_count, item.gpio_in, item.gpio_oe, item.gpio_out,
                  (item.gpio_oe != 32'h0) ? "VIP_DRIVEN" : "DUT_DRIVEN_OR_IDLE"), UVM_MEDIUM)
        ap.write(item);
      end
    end
  endtask

endclass

`endif // GPIO_MONITOR_SV
