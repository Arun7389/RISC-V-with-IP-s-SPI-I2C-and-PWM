// ============================================================================
// File: gpio_driver.sv
// Description: GPIO VIP Driver
// ============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_item);
  virtual gpio_if vif;
  int unsigned tx_count = 0;

  `uvm_component_utils(gpio_driver)

  function new(string name = "gpio_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
      `uvm_fatal("GPIO_DRV", "GPIO virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Initialize lines
    vif.gpio_out <= 32'h0;
    vif.gpio_oe  <= 32'h0;

    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      tx_count++;

      if (req.delay > 0) begin
        repeat (req.delay) @(posedge vif.clk);
      end else begin
        @(posedge vif.clk);
      end

      `uvm_info("GPIO_DRIVER", $sformatf("[TX #%0d] Driving GPIO: Mode=%s, OE=0x%08x, OUT=0x%08x, Delay=%0d cycles",
                tx_count, (req.gpio_oe != 32'h0) ? "ACTIVE_DRIVE" : "RELEASE_HIGH_Z",
                req.gpio_oe, req.gpio_out, req.delay), UVM_MEDIUM)

      // Drive values to virtual interface
      vif.gpio_out <= req.gpio_out;
      vif.gpio_oe  <= req.gpio_oe;

      @(posedge vif.clk);
      req.gpio_in = vif.gpio_in;

      `uvm_info("GPIO_DRIVER", $sformatf("[TX #%0d] Drove GPIO completed: Sampled IN=0x%08x",
                tx_count, req.gpio_in), UVM_HIGH)

      seq_item_port.item_done();
    end
  endtask

endclass

`endif // GPIO_DRIVER_SV
