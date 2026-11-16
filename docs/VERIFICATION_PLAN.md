# APEX-MAC Verification Plan

## 1. Objectives

Verify:
- Signed arithmetic in all modes.
- Round-to-nearest, ties-to-even and saturation.
- Product alignment to Q2.30.
- Accumulator arithmetic and overflow detection.
- Precision selection at every error-budget boundary.
- Accumulated error bound never exceeds the configured budget when the budget remains stable within a frame.
- Detection of a budget reduction below already-spent error.
- Reset, frame-start, valid/ready and back-pressure behavior.
- No loss, duplication or reordering of accepted transactions.

## 2. Independent reference models

Two independent references are maintained:
- Python integer model: `models/apex_mac_model.py`.
- SystemVerilog reference functions in `tb/tb_apex_mac_random.sv`.

The RTL is not used as its own golden model. The SV regression independently computes quantized operands, product bounds, precision selection, accumulator state and sticky status.

## 3. Directed test groups

1. Zero operands and zero products.
2. Positive and negative operands.
3. Minimum signed input (-32768) and maximum signed input (32767).
4. INT4 and INT8 rounding ties, including positive and negative ties.
5. Positive saturation and negative endpoint cases.
6. Budget exactly equal to the INT4 bound.
7. Budget exactly equal to the INT8 bound.
8. Budget one Q30 unit below and above a candidate bound.
9. INT4 rejected but INT8 accepted.
10. Both reduced modes rejected, forcing exact INT16.
11. Repeated operations until the error budget is nearly exhausted.
12. Dynamic budget reduction below already-spent error.
13. Positive and negative accumulator overflow boundaries.
14. Sticky overflow and accumulator hold.
15. Reset around valid transactions.
16. Frame-start asserted with in_valid high; frame-start must suppress acceptance.

## 4. Deterministic randomized regression

`tb/tb_apex_mac_random.sv` runs reproducible operand traces across multiple accumulation frames and error budgets. It compares every accepted transaction against independent SystemVerilog reference functions.

The regression is run across four configurations: native multiplier, native plus operand isolation, tiled multiplier, and tiled plus operand isolation. Each randomized run checks 264 accepted transactions (1,056 total across the four configurations). The standalone precision-tiled multiplier also passes 75,792 product checks: exhaustive INT4 (256 pairs), exhaustive INT8 (65,536 pairs), and 10,000 deterministic random INT16 pairs. The regression checks:
- Selected precision and selected error bound.
- INT4 / INT8 estimated bounds.
- Quantized operands.
- Accumulator and error-spent counters.
- Sticky overflow and budget-violation status.
- One-cycle completion pulse.
- Frame-start reset behavior.

Run all standard checks:

    make test

The random seed and generated sequence are fixed in the testbench for reproducibility. Add new seeds and corner-case distributions as coverage gaps are found.

## 5. Operand-isolation activity experiment

The activity test runs identical deterministic idle/active operand traces through native baseline and native operand-isolated variants. VCD analysis counts bit toggles on multiplier input ports. The current trace produced 9,281 baseline toggles versus 1,046 isolated toggles (88.73% fewer). This is an input-activity proxy only; it is not a power or energy measurement. Re-run with `make activity-test` and see `docs/OPERAND_ISOLATION_EXPERIMENT.md`.

## 6. Candidate SVA / formal properties

The bindable checker is in `formal/apex_mac_sva.sv`. A separate symbolic combinational harness is in `formal/apex_mac_arithmetic_formal.sv` and runs with `make formal-test`.

- A reduced-precision transaction is selected only if its bound fits the remaining budget.
- INT16 contributes zero quantization-error bound.
- error_spent_q30 is monotonic within an accumulation window.
- error_spent_q30 remains within a stable configured budget after accepted transactions.
- frame_start resets accumulator and error state atomically.
- Every accepted input produces the registered completion pulse.
- Overflow is sticky until frame reset.

The combinational arithmetic harness is intended to prove the INT4/INT8 product-error bounds and precision-controller budget decisions for all symbolic Q1.15 operand pairs and 48-bit budget values. The sequential SVA assertions have been authored but are **not yet formally proven**; they require a simulator/formal tool with concurrent SVA and bind support. See `formal/README.md`.

## 7. Coverage

Cover every selected precision, every precision transition, exact-fit and insufficient-budget cases, operand magnitude bins, sign combinations, saturation and rounding events, overflow/no-overflow cases, accumulation lengths, budget reduction and handshake stalls.

## 8. Verification release evidence

- Python model tests.
- Directed RTL simulation regression.
- Randomized RTL regression with reproducible seed in both isolation settings.
- Archived VCD and multiplier-input toggle report.
- Assertion results.
- Formal proof logs for supported properties.
- Functional coverage report.
- Tool versions and exact commands.
- Representative corner-case waveforms.
