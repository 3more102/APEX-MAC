# RTL

The synthesizable SystemVerilog implementation will be added after the arithmetic contract, transaction protocol and novelty gate are reviewed.

Planned initial modules:
- apex_mac_pkg.sv
- operand_quantizer.sv
- error_bound_estimator.sv
- precision_controller.sv
- error_budget_tracker.sv
- precision_scalable_multiplier.sv
- accumulator.sv
- apex_mac_top.sv

The Python reference model is the independent functional reference. RTL must not be treated as verified until simulation, assertions and required formal properties pass.
