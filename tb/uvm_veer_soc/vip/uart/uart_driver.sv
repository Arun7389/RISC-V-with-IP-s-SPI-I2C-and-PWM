// ============================================================================
// File: uart_driver.sv
// Description: UART VIP Driver
// ============================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);
  virtual uart_if vif;

  int unsigned baud_cycles = 5; // Matches BAUD_DIV=4 (5 clock cycles per bit)
  int unsigned tx_count = 0;

  `uvm_component_utils(uart_driver)

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal("UART_DRV", "UART virtual interface not found in config_db")
    end
    void'(uvm_config_db#(int unsigned)::get(this, "", "baud_cycles", baud_cycles));
  endfunction

  virtual task run_phase(uvm_phase phase);
    int bit_idx;

    vif.uart_rx_i <= 1'b1; // Quiescent line state
    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      tx_count++;

      `uvm_info("UART_DRIVER", $sformatf("[TX #%0d] Transmitting UART Byte to DUT RX: Byte=0x%02x ('%c'), BitPeriod=%0d cycles, Format=8-N-1",
                tx_count, req.data, (req.data >= 32 && req.data <= 126) ? req.data : ".", baud_cycles), UVM_MEDIUM)

      // Start bit: logic 0
      vif.uart_rx_i <= 1'b0;
      repeat (baud_cycles) @(posedge vif.clk);

      // 8 Data bits: LSB first
      for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
        vif.uart_rx_i <= req.data[bit_idx];
        repeat (baud_cycles) @(posedge vif.clk);
      end

      // Stop bit: logic 1
      vif.uart_rx_i <= 1'b1;
      repeat (baud_cycles) @(posedge vif.clk);

      `uvm_info("UART_DRIVER", $sformatf("[TX #%0d] Completed Transmitting UART Byte 0x%02x ('%c')",
                tx_count, req.data, (req.data >= 32 && req.data <= 126) ? req.data : "."), UVM_HIGH)

      seq_item_port.item_done();
    end
  endtask

endclass

`endif // UART_DRIVER_SV
