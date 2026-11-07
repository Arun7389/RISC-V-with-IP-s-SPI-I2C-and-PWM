// ============================================================================
// File: gpio_scoreboard.sv
// Description: GPIO VIP Scoreboard
// ============================================================================

`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

class gpio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gpio_scoreboard)

  uvm_analysis_imp #(gpio_item, gpio_scoreboard) item_export;

  int unsigned total_samples;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "gpio_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export   = new("item_export", this);
    total_samples = 0;
    pass_count    = 0;
    fail_count    = 0;
  endfunction

  virtual function void write(gpio_item item);
    bit check_ok;
    total_samples++;

    if (item.gpio_oe != 32'h0) begin
      check_ok = ((item.gpio_in & item.gpio_oe) === (item.gpio_out & item.gpio_oe)) &&
                 (!$isunknown(item.gpio_in & item.gpio_oe));
      if (check_ok) begin
        pass_count++;
        `uvm_info(get_type_name(), $sformatf("GPIO check PASS: VIP out=0x%08x matched in=0x%08x (oe=0x%08x)",
                  item.gpio_out, item.gpio_in, item.gpio_oe), UVM_HIGH)
      end else begin
        fail_count++;
        `uvm_error(get_type_name(), $sformatf("GPIO check FAIL: VIP out=0x%08x mismatch in=0x%08x (oe=0x%08x)",
                   item.gpio_out, item.gpio_in, item.gpio_oe))
      end
    end else begin
      if (!$isunknown(item.gpio_in)) begin
        pass_count++;
        `uvm_info(get_type_name(), $sformatf("GPIO check PASS: Clean pad level 0x%08x observed", item.gpio_in), UVM_HIGH)
      end else begin
        fail_count++;
        `uvm_error(get_type_name(), $sformatf("GPIO check FAIL: Detected unknown bits in gpio_in: 0x%08x", item.gpio_in))
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("GPIO Scoreboard Report: Total=%0d, PASS=%0d, FAIL=%0d",
              total_samples, pass_count, fail_count), UVM_LOW)
  endfunction

endclass

`endif // GPIO_SCOREBOARD_SV
