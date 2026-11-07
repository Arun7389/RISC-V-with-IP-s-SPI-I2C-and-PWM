// ============================================================================
// File: i2c_scoreboard.sv
// Description: I2C VIP Scoreboard
// ============================================================================

`ifndef I2C_SCOREBOARD_SV
`define I2C_SCOREBOARD_SV

class i2c_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(i2c_scoreboard)

  uvm_analysis_imp #(i2c_item, i2c_scoreboard) item_export;

  int unsigned total_transactions;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "i2c_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export        = new("item_export", this);
    total_transactions = 0;
    pass_count         = 0;
    fail_count         = 0;
  endfunction

  virtual function void write(i2c_item item);
    bit expected_ack;
    bit check_ok;

    total_transactions++;
    expected_ack = (item.addr == 7'h50) ? 1'b0 : 1'b1;
    check_ok     = (item.ack === expected_ack);

    if (check_ok) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("I2C check PASS: Target address 0x%02x validated with ACK=%0b (exp %0b)",
                item.addr, item.ack, expected_ack), UVM_HIGH)
    end else begin
      fail_count++;
      `uvm_error(get_type_name(), $sformatf("I2C check FAIL: Target address 0x%02x ACK=%0b (exp %0b)",
                 item.addr, item.ack, expected_ack))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("I2C Scoreboard Report: Total=%0d, PASS=%0d, FAIL=%0d",
              total_transactions, pass_count, fail_count), UVM_LOW)
  endfunction

endclass

`endif // I2C_SCOREBOARD_SV
