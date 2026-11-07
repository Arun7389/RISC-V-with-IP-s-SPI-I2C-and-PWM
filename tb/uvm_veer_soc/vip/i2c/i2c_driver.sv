// ============================================================================
// File: i2c_driver.sv
// Description: I2C VIP Driver with Master Stimulus & Slave Responder Support
// ============================================================================

`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_item);
  virtual i2c_if vif;

  bit [6:0] slave_addr = 7'h50;
  bit [7:0] memory[bit [7:0]];
  bit       driving_master = 1'b0;
  int unsigned tx_count = 0;
  int unsigned slave_resp_count = 0;

  `uvm_component_utils(i2c_driver)

  function new(string name = "i2c_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
      `uvm_fatal("I2C_DRV", "I2C virtual interface not found in config_db")
    end
    // Initialize default memory
    memory[8'h00] = 8'hA5;
    memory[8'h01] = 8'h5A;
  endfunction

  // Drive an I2C transaction onto the physical bus from sequence request
  task drive_i2c_transaction(i2c_item req);
    int bit_cnt;
    tx_count++;

    driving_master = 1'b1;
    `uvm_info("I2C_DRIVER", $sformatf("[TX #%0d] Master Stimulus: Addr=0x%02x (7-bit), Op=%s, Data=0x%02x, ExpACK=%s",
              tx_count, req.addr, req.r_w ? "READ" : "WRITE", req.data, req.ack ? "NACK" : "ACK"), UVM_MEDIUM)

    // Bus Idle (both lines pulled high)
    vif.scl_en  <= 1'b0;
    vif.scl_drv <= 1'b0;
    vif.sda_en  <= 1'b0;
    vif.sda_drv <= 1'b0;
    repeat (10) @(posedge vif.clk);

    // START condition: SDA goes low while SCL is high
    `uvm_info("I2C_DRIVER", $sformatf("[TX #%0d] Driving I2C START condition", tx_count), UVM_HIGH)
    vif.sda_drv <= 1'b0;
    vif.sda_en  <= 1'b1;
    repeat (5) @(posedge vif.clk);
    vif.scl_drv <= 1'b0;
    vif.scl_en  <= 1'b1;
    repeat (5) @(posedge vif.clk);

    // 7-bit Address
    for (bit_cnt = 6; bit_cnt >= 0; bit_cnt--) begin
      vif.sda_en <= (req.addr[bit_cnt] == 1'b0); // 0 = drive low, 1 = release
      repeat (5) @(posedge vif.clk);
      vif.scl_en <= 1'b0; // SCL high
      repeat (5) @(posedge vif.clk);
      vif.scl_en <= 1'b1; // SCL low
      repeat (5) @(posedge vif.clk);
    end

    // R/W bit
    vif.sda_en <= (req.r_w == 1'b0);
    repeat (5) @(posedge vif.clk);
    vif.scl_en <= 1'b0; // SCL high
    repeat (5) @(posedge vif.clk);
    vif.scl_en <= 1'b1; // SCL low
    repeat (5) @(posedge vif.clk);

    // ACK bit
    vif.sda_en <= (req.ack == 1'b0);
    repeat (5) @(posedge vif.clk);
    vif.scl_en <= 1'b0; // SCL high
    repeat (5) @(posedge vif.clk);
    vif.scl_en <= 1'b1; // SCL low
    repeat (5) @(posedge vif.clk);

    // STOP condition: SDA goes high while SCL is high
    vif.sda_en <= 1'b1; // SDA low
    repeat (5) @(posedge vif.clk);
    vif.scl_en <= 1'b0; // SCL high
    repeat (5) @(posedge vif.clk);
    vif.sda_en <= 1'b0; // SDA released high -> STOP
    repeat (10) @(posedge vif.clk);

    `uvm_info("I2C_DRIVER", $sformatf("[TX #%0d] Master Stimulus Completed: Driven STOP condition", tx_count), UVM_HIGH)
    driving_master = 1'b0;
  endtask

  virtual task run_phase(uvm_phase phase);
    vif.scl_en  <= 1'b0;
    vif.scl_drv <= 1'b0;
    vif.sda_en  <= 1'b0;
    vif.sda_drv <= 1'b0;

    @(posedge vif.rst_n);

    fork
      // Thread 1: Process sequence requests
      forever begin
        seq_item_port.get_next_item(req);
        if (req != null) begin
          drive_i2c_transaction(req);
        end
        seq_item_port.item_done();
      end

      // Thread 2: External Slave Responder (when DUT acts as Master)
      forever begin
        bit [6:0] captured_addr;
        bit       captured_rw;
        bit [7:0] rx_byte;
        int       bit_cnt;

        @(negedge vif.sda);
        if (!driving_master && vif.scl === 1'b1) begin
          slave_resp_count++;

          // Capture 7-bit Address
          captured_addr = 7'h0;
          for (bit_cnt = 6; bit_cnt >= 0; bit_cnt--) begin
            @(posedge vif.scl);
            captured_addr[bit_cnt] = vif.sda;
          end

          // Capture R/W bit
          @(posedge vif.scl);
          captured_rw = vif.sda;

          `uvm_info("I2C_DRIVER", $sformatf("[SLAVE RESP #%0d] Detected DUT Master START: Addr=0x%02x, R/W=%s (Match=%s)",
                    slave_resp_count, captured_addr, captured_rw ? "READ" : "WRITE",
                    (captured_addr == slave_addr) ? "YES" : "NO"), UVM_MEDIUM)

          if (captured_addr == slave_addr) begin
            // Send ACK
            @(negedge vif.scl);
            vif.sda_drv <= 1'b0;
            vif.sda_en  <= 1'b1;
            @(negedge vif.scl);
            vif.sda_en  <= 1'b0;

            if (captured_rw == 1'b0) begin
              // Write
              rx_byte = 8'h0;
              for (bit_cnt = 7; bit_cnt >= 0; bit_cnt--) begin
                @(posedge vif.scl or negedge vif.rst_n);
                if (!vif.rst_n) break;
                rx_byte[bit_cnt] = vif.sda;
              end
              @(negedge vif.scl);
              vif.sda_drv <= 1'b0;
              vif.sda_en  <= 1'b1;
              @(negedge vif.scl);
              vif.sda_en  <= 1'b0;

              `uvm_info("I2C_DRIVER", $sformatf("[SLAVE RESP #%0d] Received byte from DUT Master: 0x%02x, Sent ACK",
                        slave_resp_count, rx_byte), UVM_MEDIUM)
            end else begin
              // Read
              rx_byte = memory[8'h00];
              `uvm_info("I2C_DRIVER", $sformatf("[SLAVE RESP #%0d] Transmitting byte to DUT Master: 0x%02x",
                        slave_resp_count, rx_byte), UVM_MEDIUM)
              for (bit_cnt = 7; bit_cnt >= 0; bit_cnt--) begin
                vif.sda_drv <= rx_byte[bit_cnt];
                vif.sda_en  <= (rx_byte[bit_cnt] == 1'b0);
                @(negedge vif.scl);
              end
              vif.sda_en <= 1'b0;
            end
          end
        end
      end
    join
  endtask

endclass

`endif // I2C_DRIVER_SV
