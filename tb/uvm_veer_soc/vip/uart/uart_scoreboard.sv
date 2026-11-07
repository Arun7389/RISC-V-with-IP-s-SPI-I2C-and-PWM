// ============================================================================
// File: uart_scoreboard.sv
// Description: UART VIP Scoreboard
// ============================================================================

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp #(uart_item, uart_scoreboard) item_export;

  int unsigned total_bytes;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "uart_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
    total_bytes = 0;
    pass_count  = 0;
    fail_count  = 0;
  endfunction

  virtual function void write(uart_item item);
    bit check_ok;
    total_bytes++;

    // Check for expected golden byte 'V' (0x56) with clean frame
    check_ok = (item.data === 8'h56) && (!item.frame_err);

    if (check_ok) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("UART check PASS: Received expected byte=0x%02x ('%c') with no framing error",
                item.data, item.data), UVM_HIGH)
    end else if (!item.frame_err) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("UART check PASS: Received byte=0x%02x ('%c') clean frame",
                item.data, (item.data >= 32 && item.data <= 126) ? item.data : "."), UVM_HIGH)
    end else begin
      fail_count++;
      `uvm_error(get_type_name(), $sformatf("UART check FAIL: Received byte=0x%02x, FrameErr=%0b",
                 item.data, item.frame_err))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("UART Scoreboard Report: Total=%0d, PASS=%0d, FAIL=%0d",
              total_bytes, pass_count, fail_count), UVM_LOW)
  endfunction

endclass

`endif // UART_SCOREBOARD_SV
