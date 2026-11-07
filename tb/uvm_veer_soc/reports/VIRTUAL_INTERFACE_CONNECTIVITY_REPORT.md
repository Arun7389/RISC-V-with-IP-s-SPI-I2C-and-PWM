# Virtual Interface Configuration & Driver-Monitor Connectivity Report
## VeeR EL2 RISC-V SoC UVM Verification Environment

**Document Reference:** `tb/uvm_veer_soc/reports/VIRTUAL_INTERFACE_CONNECTIVITY_REPORT.md`  
**Date of Execution:** November 7, 2026  
**Project:** VeeR EL2 RISC-V System-on-Chip UVM Verification  
**Project Directory:** `/home/student/Documents/hon_070/proj_dir/`  
**Integration Directory:** `tb/uvm_veer_soc/`  
**EDA Tools:** Synopsys VCS U-2023.03_Full64, Synopsys Verdi U-2023.03-SP1  
**Methodology:** IEEE 1800.2 / UVM 1.2  

---

## 1. Executive Summary

A comprehensive inspection, formalization, and validation of the virtual interface configuration and driver-monitor connectivity for all five peripheral Verification Intellectual Properties (VIPs)—**GPIO, I2C, PWM, SPI, and UART**—has been completed.

All five VIPs are fully connected to the real RISC-V VeeR EL2 SoC top-level module (`soc_top.sv`). Virtual interface handles are registered in `uvm_config_db` at the top level before `run_test("veer_soc_test")`. Every driver and every monitor strictly validates its virtual interface handle in `build_phase` using `uvm_config_db#(...)::get(...)` and throws a fatal error (`uvm_fatal`) if missing. 

Full VCS compilation achieved **0 errors and 0 warnings**. The integrated UVM simulation verified **82/82 transactions passing with 0 failures**, the VeeR EL2 CPU core successfully executed its self-test firmware and committed the golden completion signature `0xCAFEF00D` to DMEM, and all peripheral signals were confirmed visible in the generated Verdi FSDB waveform database (`soc_top_uvm.fsdb`).

---

## 2. Interface Names and Instances

Inspection of `tb/uvm_veer_soc/tb_veer_soc_uvm.sv` and the VIP interface definitions reveals the following concrete interface types, instance names, and signal mappings:

| Peripheral VIP | Interface Type | Top-Level Instance | Key Signals in Interface | Connected DUT Port (`soc_top.sv`) | Direction & Electrical Mode |
|---|---|---|---|---|---|
| **GPIO** | `gpio_if` | `gpio_vif` | `clk`, `rst_n`, `gpio_io_pin[31:0]`, `gpio_in[31:0]`, `gpio_out[31:0]`, `gpio_oe[31:0]` | `gpio_io[31:0]` | Inout (Bidirectional Tri-state) |
| **I2C** | `i2c_if` | `i2c_vif` | `clk`, `rst_n`, `scl`, `sda`, `scl_drv`, `scl_en`, `sda_drv`, `sda_en`, `i2c_scl_in`, `i2c_sda_in` | `i2c_scl_io`, `i2c_sda_io` | Inout (Open-Drain with Pull-ups) |
| **PWM** | `pwm_if` | `pwm_vif` | `clk`, `rst_n`, `pwm_out_o` | `pwm_out_o` | Output (DUT Push-Pull to VIP) |
| **SPI** | `spi_if` | `spi_vif` | `clk`, `rst_n`, `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i` | `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i` | Master: DUT Out; Slave: VIP In/Out (`spi_miso_i`) |
| **UART** | `uart_if` | `uart_vif` | `clk`, `rst_n`, `uart_tx_o`, `uart_rx_i` | `uart_tx_o`, `uart_rx_i` | TX: DUT Out to VIP In; RX: VIP Out to DUT In |

---

## 3. Configuration Database `set()` Locations

### Top-Level Testbench (`tb/uvm_veer_soc/tb_veer_soc_uvm.sv`)
All five virtual interfaces are instantiated in module scope and registered globally in `uvm_config_db` in the `initial` block **prior to** calling `run_test("veer_soc_test")`:

```systemverilog
initial begin
  // Waveform Dumping (FSDB)
  $fsdbDumpfile("soc_top_uvm.fsdb");
  $fsdbDumpvars(0, tb_veer_soc_uvm);
  $fsdbDumpMDA();

  // Register all 5 VIP Virtual Interfaces into UVM Config DB
  uvm_config_db#(virtual gpio_if)::set(null, "*", "gpio_vif", gpio_vif);
  uvm_config_db#(virtual i2c_if)::set(null, "*", "i2c_vif", i2c_vif);
  uvm_config_db#(virtual pwm_if)::set(null, "*", "pwm_vif", pwm_vif);
  uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi_vif);
  uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", uart_vif);

  // Run Integrated Test
  run_test("veer_soc_test");
end
```

### Environment Level (`tb/uvm_veer_soc/veer_soc_env.sv`)
In addition, `veer_soc_env::build_phase` retrieves the handles and propagates them down to each agent hierarchy (`gpio_agnt*`, `i2c_agnt*`, `pwm_agnt*`, `spi_agnt*`, `uart_agnt*`):

```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  // ... Agent Instantiations ...
  if (uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", gpio_vif)) begin
    uvm_config_db#(virtual gpio_if)::set(this, "gpio_agnt*", "gpio_vif", gpio_vif);
  end
  if (uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", i2c_vif)) begin
    uvm_config_db#(virtual i2c_if)::set(this, "i2c_agnt*", "i2c_vif", i2c_vif);
  end
  if (uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", pwm_vif)) begin
    uvm_config_db#(virtual pwm_if)::set(this, "pwm_agnt*", "pwm_vif", pwm_vif);
  end
  if (uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", spi_vif)) begin
    uvm_config_db#(virtual spi_if)::set(this, "spi_agnt*", "spi_vif", spi_vif);
  end
  if (uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", uart_vif)) begin
    uvm_config_db#(virtual uart_if)::set(this, "uart_agnt*", "uart_vif", uart_vif);
  end
endfunction
```

---

## 4. Driver `get()` Implementation for All Five VIPs

All five drivers retrieve their virtual interface in `build_phase` and report a fatal error (`uvm_fatal`) with a specific tag if the interface is not found:

### GPIO Driver (`tb/uvm_veer_soc/vip/gpio/gpio_driver.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
    `uvm_fatal("GPIO_DRV", "GPIO virtual interface not found in config_db")
  end
endfunction
```

### I2C Driver (`tb/uvm_veer_soc/vip/i2c/i2c_driver.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
    `uvm_fatal("I2C_DRV", "I2C virtual interface not found in config_db")
  end
  // Initialize default memory
  memory[8'h00] = 8'hA5;
  memory[8'h01] = 8'h5A;
endfunction
```

### PWM Driver (`tb/uvm_veer_soc/vip/pwm/pwm_driver.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
    `uvm_fatal("PWM_DRV", "PWM virtual interface not found in config_db")
  end
endfunction
```

### SPI Driver (`tb/uvm_veer_soc/vip/spi/spi_driver.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)) begin
    `uvm_fatal("SPI_DRV", "SPI virtual interface not found in config_db")
  end
endfunction
```

### UART Driver (`tb/uvm_veer_soc/vip/uart/uart_driver.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
    `uvm_fatal("UART_DRV", "UART virtual interface not found in config_db")
  end
  void'(uvm_config_db#(int unsigned)::get(this, "", "baud_cycles", baud_cycles));
endfunction
```

---

## 5. Monitor `get()` Implementation for All Five VIPs

All five monitors retrieve their virtual interface in `build_phase` and report a fatal error (`uvm_fatal`) with a specific tag if the interface is not found:

### GPIO Monitor (`tb/uvm_veer_soc/vip/gpio/gpio_monitor.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
    `uvm_fatal("GPIO_MON", "GPIO virtual interface not found in config_db")
  end
endfunction
```

### I2C Monitor (`tb/uvm_veer_soc/vip/i2c/i2c_monitor.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
    `uvm_fatal("I2C_MON", "I2C virtual interface not found in config_db")
  end
endfunction
```

### PWM Monitor (`tb/uvm_veer_soc/vip/pwm/pwm_monitor.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
    `uvm_fatal("PWM_MON", "PWM virtual interface not found in config_db")
  end
endfunction
```

### SPI Monitor (`tb/uvm_veer_soc/vip/spi/spi_monitor.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)) begin
    `uvm_fatal("SPI_MON", "SPI virtual interface not found in config_db")
  end
endfunction
```

### UART Monitor (`tb/uvm_veer_soc/vip/uart/uart_monitor.sv`)
```systemverilog
virtual function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
    `uvm_fatal("UART_MON", "UART virtual interface not found in config_db")
  end
  void'(uvm_config_db#(int unsigned)::get(this, "", "baud_cycles", baud_cycles));
endfunction
```

---

## 6. Driver-to-Interface Connectivity

Each driver drives actual physical interface signals in accordance with protocol standards:

1. **GPIO Driver (`gpio_driver.sv`):**
   - Drives `vif.gpio_out` (data word) and `vif.gpio_oe` (output enable mask).
   - The interface `gpio_if.sv` converts this via tri-state continuous assignment:
     `assign gpio_io_pin[i] = gpio_oe[i] ? gpio_out[i] : 1'bz;`
   - Testbench connects `assign gpio_io = gpio_vif.gpio_io_pin;` directly to `u_soc_top.gpio_io`.
   - Supports active drive (`gpio_oe != 0`) and high-impedance release (`gpio_oe == 0`), preventing contention when the DUT drives outputs.

2. **I2C Driver (`i2c_driver.sv`):**
   - Supports dual modes: Master stimulus (Thread 1) and external Slave responder (Thread 2).
   - Respects open-drain protocol: asserts `vif.sda_en = 1` and `vif.sda_drv = 0` to pull low; deasserts `vif.sda_en = 0` to release line to high-Z.
   - Physical pull-ups (`pullup(i2c_vif.scl); pullup(i2c_vif.sda);`) in `tb_veer_soc_uvm.sv` pull released lines to logic 1.
   - Drives START, 7-bit address, R/W, and ACK/NACK handshakes.

3. **PWM Driver (`pwm_driver.sv`):**
   - Serves as the control interface for PWM sequences.
   - Samples actual DUT-driven PWM pin (`req.pwm_out_o = vif.pwm_out_o`) on clock edges and returns completed items to sequencers.

4. **SPI Driver (`spi_driver.sv`):**
   - Functions as an external SPI Slave responder to the DUT SPI Master.
   - Thread 1 accepts `spi_item` requests containing `miso_data`.
   - Thread 2 detects `negedge vif.spi_cs_n_o` (Chip Select active low) and shifts `miso_data` bits onto `vif.spi_miso_i` synchronously on `vif.spi_clk_o` edges.
   - Restores `spi_miso_i` to logic 0 upon CS deassertion.

5. **UART Driver (`uart_driver.sv`):**
   - Drives UART serial byte frames onto `vif.uart_rx_i` connected to `u_soc_top.uart_rx_i`.
   - Generates 8-N-1 frames (Start bit `0`, 8 Data bits LSB-first, Stop bit `1`) at 5 clock cycles per bit (`baud_cycles = 5`, matched to hardware `baud_div = 4`).

---

## 7. Monitor-to-Interface Sampling

All five monitors passively observe the actual interface signals connected to the DUT at valid protocol events without copying driver sequence items:

1. **GPIO Monitor (`gpio_monitor.sv`):**
   - Continuously samples `vif.gpio_in` (which observes `gpio_io_pin`).
   - Detects state transitions (`vif.gpio_in !== prev_pin`).
   - Publishes `gpio_item` through analysis port `ap` with observed pin state and VIP driving mask.

2. **I2C Monitor (`i2c_monitor.sv`):**
   - Detects START conditions (`negedge vif.sda` while `vif.scl === 1'b1`).
   - Clocks in 7-bit target address, R/W direction bit, and ACK/NACK handshake on `posedge vif.scl`.
   - Publishes `i2c_item` through analysis port `ap`.

3. **PWM Monitor (`pwm_monitor.sv`):**
   - Continuously monitors `vif.pwm_out_o` (connected to `u_soc_top.pwm_out_o`).
   - When active, measures exact high cycles (`h_count`) and low cycles (`l_count`) to compute period (256 cycles) and duty cycle (50.00%).
   - Detects pre-enable steady-state LOW idle.
   - Publishes `pwm_item` through analysis port `ap`.

4. **SPI Monitor (`spi_monitor.sv`):**
   - Detects CS assertion (`negedge vif.spi_cs_n_o`).
   - Simultaneously samples `vif.spi_mosi_o` and `vif.spi_miso_i` on `posedge vif.spi_clk_o` for 8 clock cycles.
   - Decodes completed full-duplex byte frame and publishes `spi_item` through analysis port `ap`.

5. **UART Monitor (`uart_monitor.sv`):**
   - Detects Start bit on `negedge vif.uart_tx_o` (DUT UART TX output).
   - Samples 8 data bits at mid-bit intervals (`baud_cycles = 5`).
   - Checks Stop bit for framing errors (`frame_err`).
   - Publishes `uart_item` through analysis port `ap`.

Scoreboard Connectivity:
All five analysis ports are connected directly to `veer_soc_scoreboard` in `veer_soc_env::connect_phase`:
```systemverilog
gpio_agnt.mon.ap.connect(scb.gpio_export);
i2c_agnt.mon.ap.connect(scb.i2c_export);
pwm_agnt.mon.ap.connect(scb.pwm_export);
spi_agnt.mon.ap.connect(scb.spi_export);
uart_agnt.mon.ap.connect(scb.uart_export);
```

---

## 8. VCS Compilation Result

### Compilation Command
```bash
vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm-1.2 \
    -f tb/uvm_veer_soc/veer_soc_uvm_compile.f \
    -top tb_veer_soc_uvm -o simv_veer_uvm -kdb -lca \
    -P /home/student/snps_tools_target/verdi/U-2023.03-SP1/share/PLI/VCS/linux64/novas.tab \
    /home/student/snps_tools_target/verdi/U-2023.03-SP1/share/PLI/VCS/linux64/pli.a \
    -l tb/uvm_veer_soc/logs/compile.log +notimingcheck
```

### Result
- **Status:** PASSED
- **Compilation Errors:** 0
- **Compilation Warnings:** 0 (clean VCS build)
- **Verdi KDB Elaboration:** 0 error(s), 0 warning(s)
- **Log Location:** `tb/uvm_veer_soc/logs/compile.log`

---

## 9. Test Execution & Results

### Distinction: Inspected vs. Compiled vs. Simulated
- **Inspected:**
  - Standalone directories `tb/gpio_uvm_tb/`, `tb/i2c_uvm_tb/`, `tb/pwm_uvm_tb/`, `tb/spi_uvm_tb/`, `tb/uart_uvm_tb/` were inspected. They contain 6-line skeleton stubs generated previously with no DUT instances, no interconnect, and no compile filelists. Per Requirement 8 and 9, these were not re-created or run independently.
  - The integrated environment `tb/uvm_veer_soc/` was inspected in detail across all VIPs, sequences, scoreboards, and top-level module.
- **Compiled:**
  - The complete UVM SoC environment (`tb/uvm_veer_soc/veer_soc_uvm_compile.f`), containing all RTL, 5 VIP packages, interconnect, VeeR EL2 core, and testbench was compiled with VCS.
- **Simulated:**
  - `simv_veer_uvm` was simulated executing `veer_soc_test` coordinating `veer_soc_virtual_sequence` across 9 scenarios.

### Simulation Command
```bash
./simv_veer_uvm +UVM_VERBOSITY=UVM_MEDIUM -l tb/uvm_veer_soc/logs/simulation.log
```

### Scoreboard Functional Check Table
```text
==========================================================================
             VeeR EL2 SoC INTEGRATED UVM VERIFICATION REPORT               
==========================================================================
  Subsystem VIP    |  Total Transactions  |  PASS Count  |  FAIL Count
-------------------+----------------------+--------------+--------------
  GPIO VIP         |                  51  |          51  |           0
  I2C VIP          |                   5  |           5  |           0
  PWM VIP          |                  24  |          24  |           0
  SPI VIP          |                   1  |           1  |           0
  UART VIP         |                   1  |           1  |           0
-------------------+----------------------+--------------+--------------
  TOTAL INTEGRATED |                  82  |          82  |           0
==========================================================================
  FINAL STATUS: ALL FIVE VIP INTEGRATION CHECKS PASSED [SUCCESS]          
==========================================================================
```

### UVM Report Summary
```text
--- UVM Report Summary ---
** Report counts by severity
UVM_INFO :  319
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0
```

### VeeR EL2 Firmware Execution Status
- Total CPU Retired Instructions: 153 instructions
- Golden Completion Signature: `0xCAFEF00D` detected in `u_soc_top.dmem_inst.mem[0]`
- Golden Completion Status: `0x00000001` detected in `u_soc_top.dmem_inst.mem[1]`
- PIC Interrupt Line 1 (Timer IRQ) serviced successfully by CPU trap handler.

---

## 10. Waveform Visibility Confirmation

Waveform generation was verified using Synopsys Verdi `fsdbreport` utility on `soc_top_uvm.fsdb` (size: 474 KB).

The waveform dump contains:
1. **System Signals:**
   - `tb_veer_soc_uvm.clk` (100 MHz system clock)
   - `tb_veer_soc_uvm.rst` (power-on reset pulse)
   - `tb_veer_soc_uvm.rst_n` (active-low reset)
2. **GPIO Interface Signals:**
   - `tb_veer_soc_uvm.gpio_vif.gpio_io_pin[31:0]` (bidirectional pad)
   - `tb_veer_soc_uvm.gpio_vif.gpio_oe[31:0]` (VIP output enable)
   - `tb_veer_soc_uvm.gpio_vif.gpio_out[31:0]` (VIP driven pattern)
3. **I2C Interface Signals:**
   - `tb_veer_soc_uvm.i2c_vif.scl` (open-drain SCL line)
   - `tb_veer_soc_uvm.i2c_vif.sda` (open-drain SDA line)
4. **PWM Interface Signals:**
   - `tb_veer_soc_uvm.pwm_vif.pwm_out_o` (push-pull PWM output showing 256-cycle period, 50% duty cycle)
5. **SPI Interface Signals:**
   - `tb_veer_soc_uvm.spi_vif.spi_clk_o` (master SPI serial clock)
   - `tb_veer_soc_uvm.spi_vif.spi_cs_n_o` (active-low chip select)
   - `tb_veer_soc_uvm.spi_vif.spi_mosi_o` (master output data `0x37`)
   - `tb_veer_soc_uvm.spi_vif.spi_miso_i` (slave responder data `0xA5`)
6. **UART Interface Signals:**
   - `tb_veer_soc_uvm.uart_vif.uart_tx_o` (DUT transmitted character `'V'`, 0x56)
   - `tb_veer_soc_uvm.uart_vif.uart_rx_i` (VIP transmitted character `'K'`, 0x4B)
7. **DUT Peripheral Signals:**
   - `tb_veer_soc_uvm.u_soc_top.*` (interconnect crossbar, timer, UART, SPI, I2C, PWM, GPIO, VeeR core, DMEM, IMEM)

Sample waveform extraction at reset deassertion (200 ns – 250 ns):
```text
Time(1ps)  *c_uvm/clk *c_uvm/rst *uvm/rst_n *io_io_pin *c_vif/scl *c_vif/sda *pwm_out_o *spi_clk_o *pi_cs_n_o *pi_mosi_o *pi_miso_i *uart_tx_o *uart_rx_i
========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ==========
200000     0          1          0          *zzzzzzzzz 1          1          0          0          1          1          0          1          1         
205000     1          0          1          *zzzzzzzzz 1          1          0          0          1          1          0          1          0         
210000     0          0          1          *zzzzzzzzz 1          1          0          0          1          1          0          1          0         
215000     1          0          1          *zzzzzzzzz 1          1          0          0          1          1          0          1          0         
220000     0          0          1          *zzzzzzzzz 1          1          0          0          1          1          0          1          0         
225000     1          0          1          *101010101 1          1          0          0          1          1          0          1          0         
```
At 205000 ps, reset deasserts and UART driver asserts start bit (`uart_rx_i = 0`). At 225000 ps, GPIO driver drives alternating pattern `0xaaaa5555` on `gpio_io_pin`.

All five VIP interfaces and DUT signals are verified present and inspectable in Verdi.
