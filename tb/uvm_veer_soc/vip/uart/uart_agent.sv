// ============================================================================
// File: uart_agent.sv
// Description: UART VIP Agent
// ============================================================================

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;
  uart_driver    drv;
  uart_monitor   mon;
  uart_sequencer seqr;
  uart_coverage  cov;

  `uvm_component_utils(uart_agent)

  function new(string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = uart_monitor::type_id::create("mon", this);
    cov = uart_coverage::type_id::create("cov", this);

    if (get_is_active() == UVM_ACTIVE) begin
      drv  = uart_driver::type_id::create("drv", this);
      seqr = uart_sequencer::type_id::create("seqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mon.ap.connect(cov.analysis_export);

    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass

`endif // UART_AGENT_SV
