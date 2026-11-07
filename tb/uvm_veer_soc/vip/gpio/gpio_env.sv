// ============================================================================
// File: gpio_env.sv
// Description: GPIO VIP Environment
// ============================================================================

`ifndef GPIO_ENV_SV
`define GPIO_ENV_SV

class gpio_env extends uvm_env;
  gpio_agent      agent;
  gpio_scoreboard sb;

  `uvm_component_utils(gpio_env)

  function new(string name = "gpio_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = gpio_agent::type_id::create("agent", this);
    sb    = gpio_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.item_export);
  endfunction

endclass

`endif // GPIO_ENV_SV
