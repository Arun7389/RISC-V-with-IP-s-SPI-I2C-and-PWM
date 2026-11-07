// ============================================================================
// File: pwm_driver.sv
// Description: PWM VIP Driver (Passive stimulus / control interface)
// ============================================================================

`ifndef PWM_DRIVER_SV
`define PWM_DRIVER_SV

class pwm_driver extends uvm_driver #(pwm_item);
  virtual pwm_if vif;
  int unsigned tx_count = 0;

  `uvm_component_utils(pwm_driver)

  function new(string name = "pwm_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
      `uvm_fatal("PWM_DRV", "PWM virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      tx_count++;
      @(posedge vif.clk);
      req.pwm_out_o = vif.pwm_out_o;

      `uvm_info("PWM_DRIVER", $sformatf("[TX #%0d] Processed PWM sample request: vif.pwm_out_o=%0b",
                tx_count, vif.pwm_out_o), UVM_MEDIUM)

      seq_item_port.item_done();
    end
  endtask

endclass

`endif // PWM_DRIVER_SV
