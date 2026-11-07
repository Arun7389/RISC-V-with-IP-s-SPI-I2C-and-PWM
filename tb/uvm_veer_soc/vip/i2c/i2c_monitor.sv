// ============================================================================
// File: i2c_monitor.sv
// Description: I2C VIP Protocol Monitor
// ============================================================================

`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

class i2c_monitor extends uvm_monitor;
  virtual i2c_if vif;
  uvm_analysis_port #(i2c_item) ap;
  int unsigned obs_count = 0;

  `uvm_component_utils(i2c_monitor)

  function new(string name = "i2c_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
      `uvm_fatal("I2C_MON", "I2C virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    i2c_item item;
    int bit_cnt;

    @(posedge vif.rst_n);

    forever begin
      // Wait for START condition
      @(negedge vif.sda);
      if (vif.scl === 1'b1) begin
        obs_count++;
        item = i2c_item::type_id::create("item");
        item.is_start = 1'b1;

        // Decode Address
        for (bit_cnt = 6; bit_cnt >= 0; bit_cnt--) begin
          @(posedge vif.scl);
          item.addr[bit_cnt] = vif.sda;
        end

        // Decode R/W
        @(posedge vif.scl);
        item.r_w = vif.sda;

        // Decode ACK/NACK
        @(posedge vif.scl);
        item.ack = vif.sda; // 0 = ACK, 1 = NACK

        `uvm_info("I2C_MONITOR", $sformatf("[OBS #%0d] Sampled I2C Transfer: Addr=0x%02x (7-bit), Op=%s, Handshake=%s (bit=%0b)",
                  obs_count, item.addr, item.r_w ? "READ" : "WRITE",
                  item.ack ? "NACK" : "ACK", item.ack), UVM_MEDIUM)

        ap.write(item);
      end
    end
  endtask

endclass

`endif // I2C_MONITOR_SV
