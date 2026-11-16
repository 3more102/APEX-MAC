# APEX-MAC Formal / Assertion Plan

## Combinational arithmetic proof

The symbolic harness is in formal/apex_mac_arithmetic_formal.sv. Run it with:

    make formal-test

The Yosys SAT job attempts to prove, for all signed Q1.15 operand pairs and symbolic 48-bit budget/spent values:
- The INT4 product-error bound dominates the actual absolute product error.
- The INT8 product-error bound dominates the actual absolute product error.
- The INT8 bound is no larger than the INT4 bound.
- The precision controller selects INT4 / INT8 only when the selected bound fits the remaining budget.
- Exact INT16 has zero quantization-error cost.

A successful combinational proof does not prove sequential protocol behavior, accumulator overflow handling, physical timing, or power.

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

The bindable SVA file is not part of the Icarus flow because Icarus does not support the full concurrent-SVA/bind feature set used here. The sequential SVA properties have **not yet been run through a formal engine**. The combinational arithmetic proof is a separate, narrower proof and must not be described as a full sequential proof.

## Next formal milestone

1. Select and pin a supported toolchain (for example Questa Formal or an OSS-CAD-Suite SymbiYosys flow with compatible SystemVerilog frontend support).
2. Add a harness constraining reset and frame-budget stability.
3. Prove precision-selection and error-budget invariants for supported parameter ranges.
4. Prove overflow detection and frame-reset behavior.
5. Archive tool versions, assumptions, proof depth/engine, logs and results.
