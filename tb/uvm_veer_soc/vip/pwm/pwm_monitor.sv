// ============================================================================
// File: pwm_monitor.sv
// Description: PWM VIP Waveform Monitor and Duty-Cycle Analyzer
// ============================================================================

`ifndef PWM_MONITOR_SV
`define PWM_MONITOR_SV

class pwm_monitor extends uvm_monitor;
  virtual pwm_if vif;
  uvm_analysis_port #(pwm_item) ap;
  int unsigned obs_count = 0;
  bit last_was_idle = 0;

  `uvm_component_utils(pwm_monitor)

  function new(string name = "pwm_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
      `uvm_fatal("PWM_MON", "PWM virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    pwm_item item;
    int unsigned h_count;
    int unsigned l_count;
    int unsigned wait_cycles;

    @(posedge vif.rst_n);

    forever begin
      // Wait for a rising edge of PWM_OUT or check steady-state
      wait_cycles = 0;
      while (vif.pwm_out_o !== 1'b1 && wait_cycles < 2000) begin
        @(posedge vif.clk);
        wait_cycles++;
      end

      if (vif.pwm_out_o === 1'b1) begin
        last_was_idle = 0;
        // Count HIGH cycles
        h_count = 0;
        while (vif.pwm_out_o === 1'b1) begin
          @(posedge vif.clk);
          h_count++;
        end

        // Count LOW cycles until next rising edge
        l_count = 0;
        while (vif.pwm_out_o === 1'b0 && l_count < 2000) begin
          @(posedge vif.clk);
          l_count++;
        end

        if (h_count > 0 && l_count > 0) begin
          obs_count++;
          item = pwm_item::type_id::create("item");
          item.pwm_out_o      = 1'b1;
          item.high_cycles    = h_count;
          item.low_cycles     = l_count;
          item.period_cycles  = h_count + l_count;
          item.duty_cycle_pct = (real'(h_count) * 100.0) / real'(item.period_cycles);
          item.enabled        = 1'b1;

          `uvm_info("PWM_MONITOR", $sformatf("[OBS #%0d] Measured PWM Waveform: Period=%0d cycles, High=%0d, Low=%0d, Duty=%.2f%%, State=ACTIVE",
                    obs_count, item.period_cycles, item.high_cycles, item.low_cycles, item.duty_cycle_pct), UVM_MEDIUM)

          ap.write(item);
        end
      end else begin
        // Steady-state low (0% duty cycle)
        item = pwm_item::type_id::create("item");
        item.pwm_out_o      = 1'b0;
        item.high_cycles    = 0;
        item.low_cycles     = wait_cycles;
        item.period_cycles  = wait_cycles;
        item.duty_cycle_pct = 0.0;
        item.enabled        = 1'b0;
        if (!last_was_idle) begin
          obs_count++;
          `uvm_info("PWM_MONITOR", $sformatf("[OBS #%0d] Measured PWM Output State: Steady LOW (0%% duty cycle, State=IDLE)", obs_count), UVM_MEDIUM)
          last_was_idle = 1;
        end
        ap.write(item);
        @(posedge vif.clk);
      end
    end
  endtask

endclass

`endif // PWM_MONITOR_SV
