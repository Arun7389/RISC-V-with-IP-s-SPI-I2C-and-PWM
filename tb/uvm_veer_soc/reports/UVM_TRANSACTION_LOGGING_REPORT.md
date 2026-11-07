# UVM Transaction Logging Report
## VeeR EL2 RISC-V SoC — Integrated UVM Testbench

**Date:** 2026-11-07  
**Integration Directory:** `tb/uvm_veer_soc/`  
**Verbosity Level Used:** `+UVM_VERBOSITY=UVM_MEDIUM`  
**VCS Version:** U-2023.03  
**UVM Version:** 1.2

---

## 1. Summary of Changes

All five integration VIP drivers and monitors in `tb/uvm_veer_soc/vip/` were enhanced with real-time transaction logging using `uvm_info` at `UVM_MEDIUM` verbosity. The scoreboard check-pass messages were also promoted from `UVM_HIGH` to `UVM_MEDIUM` so they appear in every standard simulation run.

**No files outside `tb/uvm_veer_soc/` were modified.**  
All original `tb/*_uvm_tb/` standalone VIP directories are unchanged.

---

## 2. Files Modified

| File | Type | Change |
|---|---|---|
| `tb/uvm_veer_soc/vip/gpio/gpio_driver.sv` | Driver | Added `GPIO_DRIVER` tag, `[TX #N]` counter, mode/OE/OUT/delay logging |
| `tb/uvm_veer_soc/vip/gpio/gpio_monitor.sv` | Monitor | Added `GPIO_MONITOR` tag, `[OBS #N]` counter, pin/OE/source logging |
| `tb/uvm_veer_soc/vip/i2c/i2c_driver.sv` | Driver | Added `I2C_DRIVER` tag, `[TX #N]` master stimulus + slave responder logging |
| `tb/uvm_veer_soc/vip/i2c/i2c_monitor.sv` | Monitor | Added `I2C_MONITOR` tag, `[OBS #N]` decoded addr/op/handshake |
| `tb/uvm_veer_soc/vip/pwm/pwm_driver.sv` | Driver | Added `PWM_DRIVER` tag, `[TX #N]` with sampled `pwm_out_o` state |
| `tb/uvm_veer_soc/vip/pwm/pwm_monitor.sv` | Monitor | Added `PWM_MONITOR` tag, `[OBS #N]` measured period/duty/state, idle-only-once guard |
| `tb/uvm_veer_soc/vip/spi/spi_driver.sv` | Driver | Added `SPI_DRIVER` tag, `[TX #N]` MISO response config + `[XFER #N]` CS_N assertion logs |
| `tb/uvm_veer_soc/vip/spi/spi_monitor.sv` | Monitor | Added `SPI_MONITOR` tag, `[OBS #N]` MOSI/MISO full-duplex frame log |
| `tb/uvm_veer_soc/vip/uart/uart_driver.sv` | Driver | Added `UART_DRIVER` tag, `[TX #N]` byte/char/baud/format log |
| `tb/uvm_veer_soc/vip/uart/uart_monitor.sv` | Monitor | Added `UART_MONITOR` tag, `[OBS #N]` sampled DUT TX byte/char/frame-err/baud |
| `tb/uvm_veer_soc/scoreboards/veer_soc_scoreboard.sv` | Scoreboard | Promoted per-VIP PASS check messages from `UVM_HIGH` to `UVM_MEDIUM` |

---

## 3. Component Tag Summary

| Component Tag | Verbosity | Description |
|---|---|---|
| `GPIO_DRIVER` | UVM_MEDIUM | Mode (ACTIVE_DRIVE/RELEASE_HIGH_Z), OE, OUT, delay per TX |
| `GPIO_MONITOR` | UVM_MEDIUM | Observed pin value, OE, source (VIP/DUT) per transition |
| `I2C_DRIVER` | UVM_MEDIUM | Master: addr/op/data/ack per TX; Slave: detected DUT START/byte exchange |
| `I2C_MONITOR` | UVM_MEDIUM | Decoded addr/op/handshake per observed I2C START |
| `PWM_DRIVER` | UVM_MEDIUM | Sampled `pwm_out_o` level per sequence request |
| `PWM_MONITOR` | UVM_MEDIUM | Measured period/high/low cycles/duty % per waveform; IDLE once-only |
| `SPI_DRIVER` | UVM_MEDIUM | Configured MISO per TX; CS_N assert/deassert per physical transfer |
| `SPI_MONITOR` | UVM_MEDIUM | Sampled MOSI/MISO per complete 8-bit frame |
| `UART_DRIVER` | UVM_MEDIUM | Transmitted byte (hex+char), baud period, 8-N-1 format per TX |
| `UART_MONITOR` | UVM_MEDIUM | Sampled DUT TX byte (hex+char), frame error, baud cycles per byte |

---

## 4. Compilation Result

```
VCS compilation: 0 errors, 0 warnings
CPU time: 8.270s compile + .232s elab + .235s link
Verdi KDB elaboration done: 0 error(s), 0 warning(s)
```

---

## 5. Simulation Terminal Log Excerpts (UVM_MEDIUM)

### GPIO Driver and Monitor
```
[GPIO_DRIVER] [TX #1] Driving GPIO: Mode=  ACTIVE_DRIVE, OE=0xffffffff, OUT=0xaaaa5555, Delay=2 cycles
[GPIO_MONITOR][OBS #1] Observed GPIO Pin Transition: Pin=0xaaaa5555 (VIP OE=0xffffffff, VIP OUT=0xaaaa5555, Source=VIP_DRIVEN)
[SCB_GPIO]    GPIO VIP-driven check PASS: Observed=0xaaaa5555 matched Expected=0xaaaa5555 (OE=0xffffffff)
[GPIO_DRIVER] [TX #3] Driving GPIO: Mode=RELEASE_HIGH_Z, OE=0x00000000, OUT=0x00000000, Delay=2 cycles
[GPIO_MONITOR][OBS #3] Observed GPIO Pin Transition: Pin=0x00000000 Source=DUT_DRIVEN_OR_IDLE
[SCB_GPIO]    GPIO DUT-driven check PASS: Clean pad level 0x00000000 observed
```

### I2C Driver and Monitor
```
[I2C_DRIVER]  [TX #1] Master Stimulus: Addr=0x50 (7-bit), Op=WRITE, Data=0xa5, ExpACK= ACK
[I2C_MONITOR] [OBS #1] Sampled I2C Transfer: Addr=0x50 (7-bit), Op=WRITE, Handshake= ACK (bit=0)
[SCB_I2C]     I2C Protocol check PASS: Addr=0x50, R/W=0, ACK=0 (Matched Expected ACK=0)
```

### PWM Monitor (measured from DUT PWM output pin)
```
[PWM_MONITOR] [OBS #1] Measured PWM Output State: Steady LOW (0% duty cycle, State=IDLE)
[PWM_MONITOR] [OBS #2] Measured PWM Waveform: Period=256 cycles, High=128, Low=128, Duty=50.00%, State=ACTIVE
[PWM_MONITOR] [OBS #3] Measured PWM Waveform: Period=256 cycles, High=128, Low=128, Duty=50.00%, State=ACTIVE
```

### SPI Driver and Monitor
```
[SPI_DRIVER]  [TX #1] Configured SPI Slave Response: MISO=0xa5
[SPI_MONITOR] [OBS #1] Observed SPI Full-Duplex Frame: MOSI=0x37, MISO=0xa5 (CS_N Active LOW)
[SCB_SPI]     SPI Transfer check PASS: MOSI=0x37 (exp 0x37), MISO=0xa5 (exp 0xA5)
```

### UART Driver and Monitor
```
[UART_DRIVER]  [TX #1] Transmitting UART Byte to DUT RX: Byte=0x4b ('K'), BitPeriod=5 cycles, Format=8-N-1
[UART_DRIVER]  [TX #2] Transmitting UART Byte to DUT RX: Byte=0x56 ('V'), BitPeriod=5 cycles, Format=8-N-1
[UART_MONITOR] [OBS #1] Observed DUT UART TX Byte: 0x56 ('V') [FrameErr=0, BitPeriod=5 cycles]
[SCB_UART]     UART Transmission check PASS: Received byte=0x56 ('V') with no framing error
```

---

## 6. Final Verification Report

```
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
UVM_WARNING :    0
UVM_ERROR   :    0
```

---

## 7. VeeR EL2 Core Execution Status

```
[CPU_FIRMWARE] FIRMWARE GOLDEN COMPLETION SIGNATURE DETECTED!
[CPU_FIRMWARE]   DMEM[0] = 0xcafef00d  (Expected 0xCAFEF00D)
[CPU_FIRMWARE]   DMEM[1] = 0x00000001  (Expected 0x00000001)
[CPU_FIRMWARE]   Total Retired Instructions: 153
```

---

## 8. Regression Comparison

| Metric | Before (Logging Task) | After (Logging Task) |
|---|---|---|
| Compile errors | 0 | 0 |
| Compile warnings | 1 (pre-existing RTL) | 1 (pre-existing RTL) |
| Simulation UVM_ERROR | 0 | 0 |
| Simulation UVM_WARNING | 0 | 0 |
| Total scoreboard checks | 82 | 82 |
| Scoreboard PASS | 82 | 82 |
| Scoreboard FAIL | 0 | 0 |
| DMEM[0] signature | 0xCAFEF00D | 0xCAFEF00D |
| Retired instructions | 153 | 153 |
| Driver TX logs at UVM_MEDIUM | None | All 5 visible |
| Monitor OBS logs at UVM_MEDIUM | Partial | All 5 visible |
| Scoreboard PASS visible at UVM_MEDIUM | No | Yes |

---

## 9. Limitations (Standalone VIP Testbenches)

The five original standalone VIP testbenches under `tb/gpio_uvm_tb/`, `tb/i2c_uvm_tb/`, `tb/pwm_uvm_tb/`, `tb/spi_uvm_tb/`, and `tb/uart_uvm_tb/` do **not** have individual VCS compile filelists (`*.f`). They cannot be independently compiled without first creating per-VIP filelists and compile scripts. This is a pre-existing limitation, not introduced by this task.

The complete runnable integrated test is `veer_soc_test`, compiled via `veer_soc_uvm_compile.f` and executed via `simv_veer_uvm`.
