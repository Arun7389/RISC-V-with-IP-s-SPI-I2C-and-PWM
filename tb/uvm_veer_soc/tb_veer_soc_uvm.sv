// ============================================================================
// File: tb_veer_soc_uvm.sv
// Description: Top-Level UVM Testbench Module for VeeR EL2 RISC-V SoC
//              Instantiates the real SoC DUT, all 5 Subsystem VIP Interfaces,
//              drives clock and reset, and connects virtual interfaces.
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

module tb_veer_soc_uvm;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import Subsystem VIP Packages & Integrated SoC Package
  import gpio_pkg::*;
  import i2c_pkg::*;
  import pwm_pkg::*;
  import spi_pkg::*;
  import uart_pkg::*;
  import veer_soc_pkg::*;

  // --------------------------------------------------------------------------
  // Primary Clocks and System Resets
  // --------------------------------------------------------------------------
  logic clk;
  logic rst;
  logic rst_n;

  // Generate 100 MHz System Clock (10 ns period)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Active-low reset derived from active-high reset
  assign rst_n = ~rst;

  // Power-on Reset Pulse Generation
  initial begin
    rst = 1'b1;
    #200;
    @(posedge clk);
    rst = 1'b0;
    `uvm_info("TB_TOP", "System Reset released. VeeR EL2 core and peripherals active.", UVM_LOW)
  end

  // --------------------------------------------------------------------------
  // Subsystem VIP Interface Declarations
  // --------------------------------------------------------------------------
  gpio_if gpio_vif();
  i2c_if  i2c_vif();
  pwm_if  pwm_vif();
  spi_if  spi_vif();
  uart_if uart_vif();

  // Distribute Clock and Reset to VIP Interfaces
  assign gpio_vif.clk   = clk;
  assign gpio_vif.rst_n = rst_n;

  assign i2c_vif.clk    = clk;
  assign i2c_vif.rst_n  = rst_n;

  assign pwm_vif.clk    = clk;
  assign pwm_vif.rst_n  = rst_n;

  assign spi_vif.clk    = clk;
  assign spi_vif.rst_n  = rst_n;

  assign uart_vif.clk   = clk;
  assign uart_vif.rst_n = rst_n;

  // --------------------------------------------------------------------------
  // Physical DUT Port Wiring & Interconnect
  // --------------------------------------------------------------------------

  // UART Pins
  wire uart_tx;
  wire uart_rx;
  wire uart_irq;
  assign uart_vif.uart_tx_o = uart_tx;
  assign uart_rx            = uart_vif.uart_rx_i;

  // SPI Pins
  wire spi_clk;
  wire spi_cs_n;
  wire spi_mosi;
  wire spi_miso;
  wire spi_irq;
  assign spi_vif.spi_clk_o  = spi_clk;
  assign spi_vif.spi_cs_n_o = spi_cs_n;
  assign spi_vif.spi_mosi_o = spi_mosi;
  assign spi_miso           = spi_vif.spi_miso_i;

  // I2C Open-Drain Bus Pins (Pullups attached to shared physical lines)
  pullup(i2c_vif.scl);
  pullup(i2c_vif.sda);
  wire i2c_irq;

  // PWM Output Pin
  wire pwm_out;
  assign pwm_vif.pwm_out_o = pwm_out;

  // Timer Interrupt Pin
  wire timer_irq;

  // GPIO 32-bit Bidirectional Bus
  wire [31:0] gpio_io;
  assign gpio_io = gpio_vif.gpio_io_pin;

  // Processor Trace & Verification Signals
  wire [31:0] trace_rv_i_insn_ip;
  wire [31:0] trace_rv_i_address_ip;
  wire        trace_rv_i_valid_ip;
  wire        trace_rv_i_exception_ip;
  wire [4:0]  trace_rv_i_ecause_ip;
  wire        trace_rv_i_interrupt_ip;
  wire [31:0] trace_rv_i_tval_ip;

  // --------------------------------------------------------------------------
  // Real VeeR EL2 System-on-Chip DUT Instantiation
  // --------------------------------------------------------------------------
  soc_top #(
      .IMEM_INIT_FILE ("firmware.hex"),
      .DMEM_INIT_FILE ("")
  ) u_soc_top (
      .clk                    (clk),
      .rst                    (rst),

      // UART external pins
      .uart_rx_i              (uart_rx),
      .uart_tx_o              (uart_tx),
      .uart_interrupt_o       (uart_irq),

      // SPI external pins
      .spi_clk_o              (spi_clk),
      .spi_cs_n_o             (spi_cs_n),
      .spi_mosi_o             (spi_mosi),
      .spi_miso_i             (spi_miso),
      .spi_interrupt_o        (spi_irq),

      // I2C external pins (open-drain)
      .i2c_scl_io             (i2c_vif.scl),
      .i2c_sda_io             (i2c_vif.sda),
      .i2c_interrupt_o        (i2c_irq),

      // PWM external output
      .pwm_out_o              (pwm_out),

      // Timer external interrupt
      .timer_irq_o            (timer_irq),

      // GPIO external pins
      .gpio_io                (gpio_io),

      // Processor Trace Interface
      .trace_rv_i_insn_ip     (trace_rv_i_insn_ip),
      .trace_rv_i_address_ip  (trace_rv_i_address_ip),
      .trace_rv_i_valid_ip    (trace_rv_i_valid_ip),
      .trace_rv_i_exception_ip(trace_rv_i_exception_ip),
      .trace_rv_i_ecause_ip   (trace_rv_i_ecause_ip),
      .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
      .trace_rv_i_tval_ip     (trace_rv_i_tval_ip)
  );

  // --------------------------------------------------------------------------
  // CPU Execution & Firmware Signature Monitoring
  // --------------------------------------------------------------------------
  integer retired_count = 0;
  reg firmware_passed = 1'b0;

  always @(posedge clk) begin
    if (!rst) begin
      if (trace_rv_i_valid_ip) begin
        retired_count <= retired_count + 1;
      end

      if (!firmware_passed && u_soc_top.dmem_inst.mem[0] == 32'hCAFEF00D) begin
        firmware_passed = 1'b1;
        `uvm_info("CPU_FIRMWARE", "========================================================", UVM_LOW)
        `uvm_info("CPU_FIRMWARE", "FIRMWARE GOLDEN COMPLETION SIGNATURE DETECTED!", UVM_LOW)
        `uvm_info("CPU_FIRMWARE", $sformatf("  DMEM[0] = 0x%08x (Expected 0xCAFEF00D)", u_soc_top.dmem_inst.mem[0]), UVM_LOW)
        `uvm_info("CPU_FIRMWARE", $sformatf("  DMEM[1] = 0x%08x (Expected 0x00000001)", u_soc_top.dmem_inst.mem[1]), UVM_LOW)
        `uvm_info("CPU_FIRMWARE", $sformatf("  Total Retired Instructions: %0d", retired_count), UVM_LOW)
        `uvm_info("CPU_FIRMWARE", "========================================================", UVM_LOW)
      end else if (u_soc_top.dmem_inst.mem[0] == 32'hDEADFA17) begin
        `uvm_error("CPU_FIRMWARE", $sformatf("FIRMWARE REPORTED SELF-TEST FAILURE: Signature=0x%08x, Status=0x%08x",
                   u_soc_top.dmem_inst.mem[0], u_soc_top.dmem_inst.mem[1]))
      end
    end
  end

  // --------------------------------------------------------------------------
  // Virtual Interface Registration, Waveform Dumping & Test Execution
  // --------------------------------------------------------------------------
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

endmodule
`default_nettype wire
