// ============================================================================
// File: uart_env.sv
// Description: UART VIP Environment
// ============================================================================

`ifndef UART_ENV_SV
`define UART_ENV_SV

class uart_env extends uvm_env;
  uart_agent      agent;
  uart_scoreboard sb;

  `uvm_component_utils(uart_env)

  function new(string name = "uart_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = uart_agent::type_id::create("agent", this);
    sb    = uart_scoreboard::type_id::create("sb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.mon.ap.connect(sb.item_export);
  endfunction

endclass

`endif // UART_ENV_SV
