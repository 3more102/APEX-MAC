# APEX-MAC Formal / Assertion Plan

## Assertion source

- `apex_mac_sva.sv`: bindable SystemVerilog Assertions for the current single-lane RTL.

The checker covers:
- One-cycle `out_valid` alignment with accepted transactions.
- Input suppression during `frame_start`.
- INT4 / INT8 decisions only when their conservative error bound fits the remaining budget.
- Zero error cost for exact INT16.
- Monotonic error-spent accounting within a frame.
- Budget safety when the configured budget is stable.
- Sticky overflow status.
- Atomic frame-state reset.
- Operand-isolation inputs are zero when idle and follow quantized operands on accepted transactions.

## Important assumptions and limits

The error-budget guarantee assumes the configured budget is stable for an accumulation frame. The RTL additionally detects a budget reduction below already-spent error and raises sticky `budget_violation`; this diagnostic behavior cannot retroactively satisfy a reduced budget.

The arithmetic guarantee is conditional on no accumulator overflow. The RTL reports sticky overflow and holds the accumulator after overflow.

## Tool support

The normal CI runs:
1. Python reference-model unit tests.
2. Directed Icarus Verilog RTL simulation.
3. Deterministic randomized Icarus Verilog RTL simulation checked against an independent testbench reference implementation.

The bindable SVA file is not yet part of the Icarus flow because Icarus does not support the full concurrent-SVA/bind feature set used here. It has **not yet been run through a formal engine**. Do not describe the design as formally proven until a supported simulator/formal tool executes the properties and proof assumptions/results are archived.

## Next formal milestone

1. Select and pin a supported toolchain (for example Questa Formal or an OSS-CAD-Suite SymbiYosys flow with compatible SystemVerilog frontend support).
2. Add a harness constraining reset and frame-budget stability.
3. Prove precision-selection and error-budget invariants for supported parameter ranges.
4. Prove overflow detection and frame-reset behavior.
5. Archive tool versions, assumptions, proof depth/engine, logs and results.
