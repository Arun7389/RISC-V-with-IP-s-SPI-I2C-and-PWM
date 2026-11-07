// ============================================================================
// File: spi_driver.sv
// Description: SPI VIP Driver (Slave Responder with Sequence Processing)
// ============================================================================

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_item);
  virtual spi_if vif;

  bit [7:0] response_data = 8'hA5;
  int unsigned tx_count = 0;
  int unsigned xfer_count = 0;

  `uvm_component_utils(spi_driver)

  function new(string name = "spi_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)) begin
      `uvm_fatal("SPI_DRV", "SPI virtual interface not found in config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.spi_miso_i <= 1'b0;
    @(posedge vif.rst_n);

    fork
      // Thread 1: Process items from sequence
      forever begin
        seq_item_port.get_next_item(req);
        if (req != null) begin
          tx_count++;
          response_data = req.miso_data;
          `uvm_info("SPI_DRIVER", $sformatf("[TX #%0d] Configured SPI Slave Response: MISO=0x%02x",
                    tx_count, response_data), UVM_MEDIUM)
        end
        @(posedge vif.clk);
        seq_item_port.item_done();
      end

      // Thread 2: SPI Slave physical bus responder
      forever begin
        int bit_idx;
        bit [7:0] shift_reg;

        // Wait for Chip Select assertion (active low)
        @(negedge vif.spi_cs_n_o);
        xfer_count++;
        `uvm_info("SPI_DRIVER", $sformatf("[XFER #%0d] CS_N Asserted (LOW). Driving Slave MISO data=0x%02x on SCLK edges",
                  xfer_count, response_data), UVM_MEDIUM)

        shift_reg = response_data;

        // Shift out bits on SCLK edges
        for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
          vif.spi_miso_i <= shift_reg[bit_idx];
          @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o or negedge vif.rst_n);
          if (vif.spi_cs_n_o || !vif.rst_n) break;
        end

        // Wait for CS_N release
        if (!vif.spi_cs_n_o) begin
          @(posedge vif.spi_cs_n_o);
        end
        `uvm_info("SPI_DRIVER", $sformatf("[XFER #%0d] CS_N Deasserted (HIGH). Slave transfer finished.",
                  xfer_count), UVM_MEDIUM)
        vif.spi_miso_i <= 1'b0;
      end
    join
  endtask

endclass

`endif // SPI_DRIVER_SV
