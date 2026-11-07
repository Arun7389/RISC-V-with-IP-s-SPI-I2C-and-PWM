// ============================================================================
// File: veer_soc_test.sv
// Description: Common Integrated UVM Base Test for VeeR EL2 RISC-V SoC
// ============================================================================

`ifndef VEER_SOC_TEST_SV
`define VEER_SOC_TEST_SV

class veer_soc_test extends uvm_test;
  `uvm_component_utils(veer_soc_test)

  veer_soc_env env;

  function new(string name = "veer_soc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = veer_soc_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    veer_soc_virtual_sequence vseq;

    phase.raise_objection(this);

    `uvm_info(get_type_name(), "============================================================", UVM_LOW)
    `uvm_info(get_type_name(), "   Starting Integrated VeeR EL2 RISC-V SoC UVM Verification   ", UVM_LOW)
    `uvm_info(get_type_name(), "   Coordinating 5 Peripheral VIPs: GPIO, I2C, PWM, SPI, UART   ", UVM_LOW)
    `uvm_info(get_type_name(), "============================================================", UVM_LOW)

    vseq = veer_soc_virtual_sequence::type_id::create("vseq");
    vseq.start(env.vseqr);

    // Allow additional cycles for post-sequence bus quiescence and full report
    #10000;

    `uvm_info(get_type_name(), "Integrated UVM Test Run Phase Completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // VEER_SOC_TEST_SV
