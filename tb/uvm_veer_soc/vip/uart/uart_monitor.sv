// ============================================================================
// File: uart_monitor.sv
// Description: UART VIP Protocol Monitor
// ============================================================================

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;

  int unsigned baud_cycles = 5; // Matches BAUD_DIV=4 (5 clock cycles per bit)
  int unsigned obs_count = 0;

  `uvm_component_utils(uart_monitor)

  function new(string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal("UART_MON", "UART virtual interface not found in config_db")
    end
    void'(uvm_config_db#(int unsigned)::get(this, "", "baud_cycles", baud_cycles));
  endfunction

  virtual task run_phase(uvm_phase phase);
    uart_item item;
    bit [7:0] captured_byte;
    int bit_idx;

    @(posedge vif.rst_n);

    forever begin
      // Wait for Start Bit (falling edge on TX line)
      @(negedge vif.uart_tx_o);

      // Verify valid start bit at mid-bit period
      repeat (baud_cycles / 2) @(posedge vif.clk);
      if (vif.uart_tx_o === 1'b0) begin
        obs_count++;
        // Sample 8 data bits at mid-bit positions
        captured_byte = 8'h0;
        for (bit_idx = 0; bit_idx < 8; bit_idx++) begin
          repeat (baud_cycles) @(posedge vif.clk);
          captured_byte[bit_idx] = vif.uart_tx_o;
        end

        // Sample Stop bit
        repeat (baud_cycles) @(posedge vif.clk);

        item = uart_item::type_id::create("item");
        item.data      = captured_byte;
        item.rx_data   = captured_byte;
        item.frame_err = (vif.uart_tx_o !== 1'b1);
        item.uart_tx_o = vif.uart_tx_o;

        `uvm_info("UART_MONITOR", $sformatf("[OBS #%0d] Observed DUT UART TX Byte: 0x%02x ('%c') [FrameErr=%0b, BitPeriod=%0d cycles]",
                  obs_count, captured_byte, (captured_byte >= 32 && captured_byte <= 126) ? captured_byte : ".",
                  item.frame_err, baud_cycles), UVM_MEDIUM)

        ap.write(item);
      end
    end
  endtask

endclass

`endif // UART_MONITOR_SV
