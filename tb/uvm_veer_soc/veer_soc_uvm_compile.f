// ============================================================================
// File: veer_soc_uvm_compile.f
// Description: VCS Compile Filelist for Integrated VeeR EL2 SoC with 5 VIPs
// ============================================================================

+define+RV_OPENSOURCE=1

// Include Directories: Processor Snapshots & Design Headers
+incdir+rtl/Cores-VeeR-EL2/snapshots/default
+incdir+rtl/Cores-VeeR-EL2/design/include
+incdir+rtl/Cores-VeeR-EL2/design/lib
+incdir+rtl/Cores-VeeR-EL2/testbench
+incdir+rtl/interconnect
+incdir+rtl/uart
+incdir+rtl/spi/include
+incdir+rtl/i2c
+incdir+rtl/timer
+incdir+rtl/gpio
+incdir+rtl/common

// Include Directories: UVM Integration Environment and VIPs
+incdir+tb/uvm_veer_soc
+incdir+tb/uvm_veer_soc/vip/gpio
+incdir+tb/uvm_veer_soc/vip/i2c
+incdir+tb/uvm_veer_soc/vip/pwm
+incdir+tb/uvm_veer_soc/vip/spi
+incdir+tb/uvm_veer_soc/vip/uart
+incdir+tb/uvm_veer_soc/sequences
+incdir+tb/uvm_veer_soc/scoreboards

// ----------------------------------------------------------------------------
// 1. VeeR EL2 Package and Library Files
// ----------------------------------------------------------------------------
rtl/Cores-VeeR-EL2/design/include/el2_def.sv
-v rtl/Cores-VeeR-EL2/design/lib/beh_lib.sv
-v rtl/Cores-VeeR-EL2/design/lib/mem_lib.sv

// ----------------------------------------------------------------------------
// 2. VeeR EL2 Core RTL
// ----------------------------------------------------------------------------
rtl/Cores-VeeR-EL2/design/lib/el2_assert.sv
rtl/Cores-VeeR-EL2/design/el2_mubi_pkg.sv
rtl/Cores-VeeR-EL2/design/el2_veer_wrapper.sv
rtl/Cores-VeeR-EL2/design/el2_lockstep_pkg.sv
rtl/Cores-VeeR-EL2/design/el2_veer_lockstep.sv
rtl/Cores-VeeR-EL2/design/el2_mem.sv
rtl/Cores-VeeR-EL2/design/el2_pic_ctrl.sv
rtl/Cores-VeeR-EL2/design/el2_veer.sv
rtl/Cores-VeeR-EL2/design/el2_dma_ctrl.sv
rtl/Cores-VeeR-EL2/design/el2_pmp.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_aln_ctl.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_compress_ctl.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ifc_ctl.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_bp_ctl.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_ic_mem.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_mem_ctl.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu_iccm_mem.sv
rtl/Cores-VeeR-EL2/design/ifu/el2_ifu.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_decode_ctl.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_gpr_ctl.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_ib_ctl.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_pmp_ctl.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_tlu_ctl.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec_trigger.sv
rtl/Cores-VeeR-EL2/design/dec/el2_dec.sv
rtl/Cores-VeeR-EL2/design/exu/el2_exu_alu_ctl.sv
rtl/Cores-VeeR-EL2/design/exu/el2_exu_mul_ctl.sv
rtl/Cores-VeeR-EL2/design/exu/el2_exu_div_ctl.sv
rtl/Cores-VeeR-EL2/design/exu/el2_exu.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_clkdomain.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_addrcheck.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_lsc_ctl.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_stbuf.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_buffer.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_intf.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_ecc.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_mem.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_ctl.sv
rtl/Cores-VeeR-EL2/design/lsu/el2_lsu_trigger.sv
rtl/Cores-VeeR-EL2/design/dbg/el2_dbg.sv
rtl/Cores-VeeR-EL2/design/dmi/dmi_mux.v
rtl/Cores-VeeR-EL2/design/dmi/dmi_wrapper.v
rtl/Cores-VeeR-EL2/design/dmi/dmi_jtag_to_core_sync.v
rtl/Cores-VeeR-EL2/design/dmi/rvjtag_tap.v
rtl/Cores-VeeR-EL2/design/lib/el2_lib.sv
rtl/Cores-VeeR-EL2/design/lib/el2_mem_if.sv
rtl/Cores-VeeR-EL2/design/lib/el2_prim_generic_buf.sv
rtl/Cores-VeeR-EL2/design/lib/el2_prim_buf.sv
rtl/Cores-VeeR-EL2/design/lib/ahb_to_axi4.sv
rtl/Cores-VeeR-EL2/design/lib/axi4_to_ahb.sv

// ----------------------------------------------------------------------------
// 3. Interconnect RTL
// ----------------------------------------------------------------------------
rtl/interconnect/priority_encoder.v
rtl/interconnect/arbiter.v
rtl/interconnect/axi_interconnect.v
rtl/interconnect/axi_interconnect_wrap_2x8.v

// ----------------------------------------------------------------------------
// 4. Peripherals RTL
// ----------------------------------------------------------------------------
rtl/timer/timer_core.sv
rtl/timer/timer_regs.sv
rtl/timer/timer_axi.sv
rtl/common/axi4lite_slave_adapter.sv

rtl/gpio/gpio_bit.sv
rtl/gpio/gpio_regs.sv
rtl/gpio/gpio_wrapper.sv
rtl/gpio/gpio_axi.sv

rtl/uart/axi_internal_fifo.v
rtl/uart/uart_parity_bit_compute.v
rtl/uart/uart_receiver.v
rtl/uart/uart_transmitter.v
rtl/uart/uart_controller.v
rtl/uart/axi_uart_top.v

rtl/spi/ratio_clk.v
rtl/spi/spi_clk_gen.v
rtl/spi/spi_valid_logic.v
rtl/spi/spi_fifo.v
rtl/spi/spi_exch_byte.v
rtl/spi/spi_ctrl.v
rtl/spi/axi_spi_ctrl.v
rtl/spi/axi_spi_top.v

rtl/i2c/i2c_master_defines.v
rtl/i2c/i2c_master_bit_ctrl.v
rtl/i2c/i2c_master_byte_ctrl.v
rtl/i2c/i2c_master_top.v

rtl/pwm/myip_v1_0_S00_AXI.v
rtl/pwm/myip_v1_0.v

// ----------------------------------------------------------------------------
// 5. System Memory & Protocol Adapters
// ----------------------------------------------------------------------------
rtl/common/axi_mem_slave.sv
rtl/common/axi_adapter_ifu.sv
rtl/common/axi_adapter_lsu.sv

// ----------------------------------------------------------------------------
// 6. SoC Top Level RTL
// ----------------------------------------------------------------------------
rtl/soc_top.sv

// ----------------------------------------------------------------------------
// 7. Subsystem VIP Interfaces
// ----------------------------------------------------------------------------
tb/uvm_veer_soc/vip/gpio/gpio_if.sv
tb/uvm_veer_soc/vip/i2c/i2c_if.sv
tb/uvm_veer_soc/vip/pwm/pwm_if.sv
tb/uvm_veer_soc/vip/spi/spi_if.sv
tb/uvm_veer_soc/vip/uart/uart_if.sv

// ----------------------------------------------------------------------------
// 8. Subsystem VIP Packages
// ----------------------------------------------------------------------------
tb/uvm_veer_soc/vip/gpio/gpio_pkg.sv
tb/uvm_veer_soc/vip/i2c/i2c_pkg.sv
tb/uvm_veer_soc/vip/pwm/pwm_pkg.sv
tb/uvm_veer_soc/vip/spi/spi_pkg.sv
tb/uvm_veer_soc/vip/uart/uart_pkg.sv

// ----------------------------------------------------------------------------
// 9. Top-Level Integrated SoC UVM Package
// ----------------------------------------------------------------------------
tb/uvm_veer_soc/veer_soc_pkg.sv

// ----------------------------------------------------------------------------
// 10. Top-Level UVM Testbench Module
// ----------------------------------------------------------------------------
tb/uvm_veer_soc/tb_veer_soc_uvm.sv
