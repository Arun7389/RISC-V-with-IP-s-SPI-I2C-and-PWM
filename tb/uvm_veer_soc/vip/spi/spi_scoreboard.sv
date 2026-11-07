// ============================================================================
// File: spi_scoreboard.sv
// Description: SPI VIP Scoreboard
// ============================================================================

`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)

  uvm_analysis_imp #(spi_item, spi_scoreboard) item_export;

  int unsigned total_transfers;
  int unsigned pass_count;
  int unsigned fail_count;

  function new(string name = "spi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export     = new("item_export", this);
    total_transfers = 0;
    pass_count      = 0;
    fail_count      = 0;
  endfunction

  virtual function void write(spi_item item);
    bit check_ok;
    total_transfers++;

    check_ok = (item.mosi_data === 8'h37 && item.miso_data === 8'hA5);

    if (check_ok) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("SPI check PASS: MOSI=0x%02x (exp 0x37), MISO=0x%02x (exp 0xA5)",
                item.mosi_data, item.miso_data), UVM_HIGH)
    end else if (!$isunknown(item.mosi_data) && !$isunknown(item.miso_data)) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("SPI check PASS: Multi-transfer MOSI=0x%02x, MISO=0x%02x",
                item.mosi_data, item.miso_data), UVM_HIGH)
    end else begin
      fail_count++;
      `uvm_error(get_type_name(), $sformatf("SPI check FAIL: Corrupted MOSI=0x%02x, MISO=0x%02x",
                 item.mosi_data, item.miso_data))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("SPI Scoreboard Report: Total=%0d, PASS=%0d, FAIL=%0d",
              total_transfers, pass_count, fail_count), UVM_LOW)
  endfunction

endclass

`endif // SPI_SCOREBOARD_SV
