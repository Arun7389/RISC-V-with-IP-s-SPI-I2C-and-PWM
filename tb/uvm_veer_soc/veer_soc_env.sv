// ============================================================================
// File: veer_soc_env.sv
// Description: Common UVM Environment instantiating all 5 VIP Agents,
//              Virtual Sequencer, and Central Scoreboard
// ============================================================================

`ifndef VEER_SOC_ENV_SV
`define VEER_SOC_ENV_SV

class veer_soc_env extends uvm_env;
  `uvm_component_utils(veer_soc_env)

  // Five Peripheral VIP Agents
  gpio_agent gpio_agnt;
  i2c_agent  i2c_agnt;
  pwm_agent  pwm_agnt;
  spi_agent  spi_agnt;
  uart_agent uart_agnt;

  // Integrated Virtual Sequencer
  veer_soc_virtual_sequencer vseqr;

  // Integrated Common Scoreboard
  veer_soc_scoreboard scb;

  // Virtual Interface Handles
  virtual gpio_if gpio_vif;
  virtual i2c_if  i2c_vif;
  virtual pwm_if  pwm_vif;
  virtual spi_if  spi_vif;
  virtual uart_if uart_vif;

  function new(string name = "veer_soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Instantiate VIP Agents
    gpio_agnt = gpio_agent::type_id::create("gpio_agnt", this);
    i2c_agnt  = i2c_agent::type_id::create("i2c_agnt",   this);
    pwm_agnt  = pwm_agent::type_id::create("pwm_agnt",   this);
    spi_agnt  = spi_agent::type_id::create("spi_agnt",   this);
    uart_agnt = uart_agent::type_id::create("uart_agnt", this);

    // Instantiate Virtual Sequencer and Scoreboard
    vseqr = veer_soc_virtual_sequencer::type_id::create("vseqr", this);
    scb   = veer_soc_scoreboard::type_id::create("scb",   this);

    // Configure Agent Interface Handles from Config DB
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

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect Monitors to Scoreboard
    gpio_agnt.mon.ap.connect(scb.gpio_export);
    i2c_agnt.mon.ap.connect(scb.i2c_export);
    pwm_agnt.mon.ap.connect(scb.pwm_export);
    spi_agnt.mon.ap.connect(scb.spi_export);
    uart_agnt.mon.ap.connect(scb.uart_export);

    // Connect Sequencers to Virtual Sequencer
    if (gpio_agnt.get_is_active() == UVM_ACTIVE) vseqr.gpio_seqr = gpio_agnt.seqr;
    if (i2c_agnt.get_is_active()  == UVM_ACTIVE) vseqr.i2c_seqr  = i2c_agnt.seqr;
    if (pwm_agnt.get_is_active()  == UVM_ACTIVE) vseqr.pwm_seqr  = pwm_agnt.seqr;
    if (spi_agnt.get_is_active()  == UVM_ACTIVE) vseqr.spi_seqr  = spi_agnt.seqr;
    if (uart_agnt.get_is_active() == UVM_ACTIVE) vseqr.uart_seqr = uart_agnt.seqr;
  endfunction

endclass

`endif // VEER_SOC_ENV_SV
