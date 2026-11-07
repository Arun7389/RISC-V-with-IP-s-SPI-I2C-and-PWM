# VeeR EL2 RISC-V SoC Integrated UVM Verification Report

**Document Reference:** `tb/uvm_veer_soc/reports/VEER_SOC_UVM_VERIFICATION_REPORT.md`  
**Date of Execution:** November 7, 2026  
**Simulation Tool:** Synopsys VCS U-2023.03_Full64  
**Debug Tool:** Synopsys Verdi U-2023.03-SP1 (KDB + FSDB Dumper)  
**UVM Methodology:** UVM 1.2  
**Target Design:** Real VeeR EL2 RISC-V System-on-Chip (`soc_top.sv`)  
**Top Testbench:** `tb/uvm_veer_soc/tb_veer_soc_uvm.sv`  
**Test Executed:** `veer_soc_test`  

---

## 1. Executive Summary

The integrated UVM 1.2 testbench for the VeeR EL2 RISC-V System-on-Chip (SoC) has been successfully continued, diagnosed, fixed, compiled, and executed to completion with **zero compilation errors, zero simulation errors, and zero UVM warnings**.

All five subsystem Verification Intellectual Properties (VIPs)—**GPIO, I2C, PWM, SPI, and UART**—are fully connected to the real SoC DUT pins, orchestrated via a top-level virtual sequencer and coordinated virtual sequence (`veer_soc_virtual_sequence`), and checked by an integrated scoreboard performing genuine expected-vs-observed functional comparisons.

Concurrently, the actual VeeR EL2 processor core booted from 64 KB IMEM, executed native RV32IMC test firmware (`firmware.hex`), tested internal DMEM memory, configured and verified peripherals via the AXI crossbar interconnect, serviced PIC interrupts via its trap handler, and wrote the golden completion signature `0xCAFEF00D` with status `0x00000001` to DMEM after retiring 153 instructions.

---

## 2. Issues Diagnosed and Resolved

| # | File / Component | Initial Symptom | Root Cause | Engineering Resolution |
|---|---|---|---|---|
| 1 | `tb/uvm_veer_soc/vip/i2c/i2c_if.sv` & `tb_veer_soc_uvm.sv` | VCS Compile Error `[ICSD]` (Illegal combination of structural drivers on `i2c_scl_in`, `i2c_sda_in`) | Both `i2c_if.sv` and `tb_veer_soc_uvm.sv` contained continuous assignments driving `i2c_scl_in` and `i2c_sda_in`. | Removed redundant assignments from `tb_veer_soc_uvm.sv`, verified and retained unified bidirectional open-drain modeling inside `i2c_if.sv`. |
| 2 | `firmware.hex` location | Potential file-not-found during `$readmemh` in run directory | DUT instantiated with `.IMEM_INIT_FILE("firmware.hex")` while `firmware.hex` was only present in subdirectories. | Placed clean copy of `firmware.hex` in run root directory and retained `tb/uvm_veer_soc/firmware.hex`. |
| 3 | `tb/uvm_veer_soc/vip/spi/spi_driver.sv` | Simulation deadlock / hang during Scenario 2 (`spi_single_transfer_seq`) | `spi_driver.sv` ran a physical CS_N monitor loop but never called `seq_item_port.get_next_item()`, causing sequence `start_item` to block indefinitely. | Implemented concurrent `fork/join` in `spi_driver.sv`: Thread 1 consumes sequence items and updates MISO response data; Thread 2 acts as the hardware SPI slave responder. |
| 4 | `tb/uvm_veer_soc/vip/i2c/i2c_driver.sv` | Simulation deadlock / hang during Scenario 3 (`i2c_slave_ack_seq`) | `i2c_driver.sv` only listened for external START conditions and never serviced `seq_item_port.get_next_item()`. | Implemented concurrent `fork/join` in `i2c_driver.sv`: Thread 1 drives I2C stimulus onto the open-drain physical lines per sequence request; Thread 2 acts as passive slave responder. |
| 5 | `tb/uvm_veer_soc/vip/uart/uart_driver.sv` & `uart_monitor.sv` | DUT transmitted byte `'V'` (0x56) was mis-sampled by monitor as `0xFF` | VIP defaulted to `baud_cycles = 64` (assuming 16x oversampling * 4), whereas RTL UART IP directly counts clocks up to `baud_div_i = 4` (5 cycles per bit). | Adjusted `baud_cycles = 5` in both `uart_driver.sv` and `uart_monitor.sv`, aligning with hardware divisor. Monitor cleanly sampled golden byte `0x56` ('V') with zero framing error. |
| 6 | `tb/uvm_veer_soc/vip/pwm/pwm_monitor.sv` | Log flooding with thousands of repetitive messages | Monitor logged `UVM_MEDIUM` on every single 2.56-us period. | Adjusted monitor reporting severity to `UVM_HIGH`, preserving data delivery to analysis port and keeping simulation logs clean and focused. |
| 7 | `tb/uvm_veer_soc/sequences/gpio_sequence.sv` | Potential bus contention when DUT drives GPIO | After driving walking patterns, VIP left `gpio_oe = 0xFFFFFFFF`, which could fight DUT outputs. | Added `gpio_release_seq` (`gpio_oe = 0x0`) and incorporated bus release into virtual sequence scenarios and reset quiescence check. |
| 8 | `tb/uvm_veer_soc/scoreboards/veer_soc_scoreboard.sv` & VIP Scoreboards | Scoreboards lacked genuine expected vs. observed data checking | Previous code only checked for `!$isunknown` or accepted arbitrary values. | Implemented genuine comparison logic for all 5 peripherals: GPIO (VIP driven vs. observed pad, clean DUT output levels); I2C (address 0x50 with ACK=0, address 0x51 with ACK=1); PWM (measured period = 256 cycles, duty cycle = 50.0% within +/-1%); SPI (MOSI = 0x37, MISO = 0xA5); UART (data = 0x56 'V', frame_err = 0). |
| 9 | `tb/uvm_veer_soc/tb_veer_soc_uvm.sv` | Top-level lacked firmware completion verification | Top-level did not check DMEM golden signature. | Added trace retirement tracking (`retired_count`) and golden completion signature detection (`0xCAFEF00D`, status `0x00000001`). |

---

## 3. SoC Architecture Verification

The SoC architecture was verified through direct inspection of `rtl/soc_top.sv` and interconnect wrapper:
- **Interconnect:** AXI 2-Master x 8-Slave Crossbar (`axi_interconnect_wrap_2x8.v`)
- **Master 0 (M0):** VeeR EL2 Instruction Fetch Unit (IFU) via 64-bit to 32-bit adapter
- **Master 1 (M1):** VeeR EL2 Load/Store Unit (LSU) via 64-bit to 32-bit adapter
- **Slave 0 (M00):** 64 KB IMEM (`0x0000_0000 - 0x0000_FFFF`)
- **Slave 1 (M01):** 32-bit Timer IP (`0x4000_4000 - 0x4000_4FFF`)
- **Slave 2 (M02):** 32-bit GPIO IP (`0x4000_5000 - 0x4000_5FFF`)
- **Slave 3 (M03):** 16550-compatible UART IP (`0x4000_0000 - 0x4000_0FFF`)
- **Slave 4 (M04):** SPI Controller IP (`0x4000_1000 - 0x4000_1FFF`)
- **Slave 5 (M05):** I2C Master IP with inline Wishbone bridge (`0x4000_2000 - 0x4000_2FFF`)
- **Slave 6 (M06):** AXI PWM IP (`0x4000_3000 - 0x4000_3FFF`)
- **Slave 7 (M07):** 64 KB DMEM (`0x0001_0000 - 0x0001_FFFF`)

---

## 4. Subsystem VIP Integration & Interface Wiring

| VIP Subsystem | Interface Name | Connected DUT Signals | Driving / Sampling Method |
|---|---|---|---|
| **GPIO** | `gpio_if` | `inout wire [31:0] gpio_io` | Tri-state: driven to `gpio_out` when `gpio_oe` is 1; released to `1'bz` when `gpio_oe` is 0. Monitored continuously via `gpio_in`. |
| **I2C** | `i2c_if` | `inout wire i2c_scl_io`<br>`inout wire i2c_sda_io` | Open-drain: pulled low to `0` when enabled, released to `1'bz` when disabled. Pullup resistors attached to both lines. |
| **PWM** | `pwm_if` | `output wire pwm_out_o` | Passive reception: DUT drives push-pull PWM. VIP monitor samples period and duty cycle. |
| **SPI** | `spi_if` | `output wire spi_clk_o`<br>`output wire spi_cs_n_o`<br>`output wire spi_mosi_o`<br>`input wire spi_miso_i` | DUT is SPI Master. VIP acts as Slave responder, shifting out `miso_data` on `spi_miso_i` when `cs_n` is active. |
| **UART** | `uart_if` | `output wire uart_tx_o`<br>`input wire uart_rx_i` | Point-to-point: VIP driver sends serial frames to `uart_rx_i` at 5 cycles/bit. VIP monitor receives DUT output on `uart_tx_o` at 5 cycles/bit. |

---

## 5. Virtual Sequence Execution & 9 Scenarios

All nine required scenarios executed to completion in `veer_soc_virtual_sequence`:

1. **Scenario 1 (`scenario_1_gpio_uart`):** Concurrent GPIO alternating bit patterns (`0xAAAA5555`, `0x5555AAAA`) with UART single-byte injection (`'K'` = 0x4B).
2. **Scenario 2 (`scenario_2_spi_gpio`):** Concurrent SPI single-transfer configuration (MISO `0xA5`) with GPIO walking-one pattern (32 bits).
3. **Scenario 3 (`scenario_3_i2c_pwm`):** Concurrent I2C slave ACK sequence (target 0x50) with PWM waveform measurement.
4. **Scenario 4 (`scenario_4_uart_spi`):** Concurrent UART multi-byte transmission (`"VeeR"`) with SPI multi-byte transfer configuration (`0x5A`, `0xC3`, `0x3C`).
5. **Scenario 5 (`scenario_5_all_concurrent`):** All 5 peripherals stressed simultaneously (GPIO mixed I/O, I2C multi-byte, PWM sampling, SPI transfer, UART byte).
6. **Scenario 6 (`scenario_6_sequential_all`):** Sequential execution through GPIO (drive 0, drive 1), UART, SPI, I2C, and PWM.
7. **Scenario 7 (`scenario_7_repeated`):** Three repeated iterations of burst transactions across GPIO, UART, and SPI.
8. **Scenario 8 (`scenario_8_reset_behavior`):** Reset quiescence check and bus release (`gpio_oe = 0x0`).
9. **Scenario 9 (`scenario_9_firmware_end_to_end`):** Monitored real VeeR EL2 core firmware execution, peripheral access, PIC interrupt servicing, and completion signature store.

---

## 6. Scoreboard Verification Results

The integrated scoreboard (`veer_soc_scoreboard`) registered the following verification metrics:

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

### Specific Checks Performed:
- **GPIO (51 checks):** Verified driven pins match sequence values (`0xAAAA5555`, `0x5555AAAA`, 32 walking-one positions, mixed masks); verified clean logic levels during DUT drive and bus release.
- **I2C (5 checks):** Verified target address `0x50` with `ACK = 0` (5 valid bus frames observed and checked).
- **PWM (24 checks):** Verified measured period = 256 clock cycles and measured duty cycle = 50.0% (+/-1.0% tolerance).
- **SPI (1 check):** Verified MOSI data = `0x37` and MISO data = `0xA5` during active DUT SPI master transfer.
- **UART (1 check):** Verified DUT transmission of golden character `'V'` (`0x56`) with `frame_err = 0` at 5 cycles/bit.

---

## 7. Firmware Execution Results

- **Processor Core:** Real Western Digital / CHIPS Alliance VeeR EL2 core
- **Reset Duration:** 200 ns
- **Retired Instructions:** 153 instructions
- **Execution Completion Time:** 55.435 us (simulation time)
- **Golden Signature at DMEM[0] (0x00010000):** `0xCAFEF00D` (MATCH)
- **Status Word at DMEM[1] (0x00010004):** `0x00000001` (MATCH - ALL CPU TESTS PASSED)
- **Interrupt Serviced:** Timer IRQ 1 serviced by VeeR PIC and Trap Handler, incrementing interrupt counter at `0x00010010`.

---

## 8. Artifacts and File Deliverables

- **VCS Compilation Log:** `tb/uvm_veer_soc/logs/compile.log` (62 KB)
- **Simulation Log:** `tb/uvm_veer_soc/logs/simulation.log` (26 KB)
- **FSDB Waveform Database:** `soc_top_uvm.fsdb` (474 KB)
- **Compile Filelist:** `tb/uvm_veer_soc/veer_soc_uvm_compile.f`
- **Connectivity Specification:** `tb/uvm_veer_soc/connectivity/VIP_DUT_CONNECTIVITY.md`
- **Firmware Hex File:** `tb/uvm_veer_soc/firmware.hex` & `firmware.hex`
- **Verification Report:** `tb/uvm_veer_soc/reports/VEER_SOC_UVM_VERIFICATION_REPORT.md`
