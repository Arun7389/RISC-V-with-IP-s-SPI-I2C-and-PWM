// ============================================================================
// File: i2c_env.sv
// Description: I2C VIP Environment
// ============================================================================

`ifndef I2C_ENV_SV
`define I2C_ENV_SV

class i2c_env extends uvm_env;
  i2c_agent      agent;
  i2c_scoreboard sb;

  `uvm_component_utils(i2c_env)

  function new(string name = "i2c_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = i2c_agent::type_id::create("agent", this);
    sb    = i2c_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.item_export);
  endfunction

endclass

`endif // I2C_ENV_SV
