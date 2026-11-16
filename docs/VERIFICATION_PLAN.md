# APEX-MAC Verification Plan

## 1. Verification objectives

Verify:
- Signed arithmetic correctness in all modes.
- Round-to-nearest and saturation behavior.
- Product alignment to Q2.30.
- Accumulator correctness and overflow detection.
- Correct precision selection at every error-budget boundary.
- The accumulated error bound never exceeds the configured budget.
- Reset, frame-start, valid/ready and back-pressure behavior.
- No loss, duplication or reordering of accepted transactions.

## 2. Reference model

Create an independent Python model using integer arithmetic and high-precision rational/decimal calculations. The model must produce:
- Quantized operands for each mode.
- Exact and quantized products.
- Product alignment.
- Per-operation error bound.
- Accumulated exact result, approximate result and absolute error.
- Selected precision and remaining error budget.

Do not use the RTL implementation as the golden model.

## 3. Directed test groups

1. Zero operands and zero products.
2. Positive and negative values.
3. Minimum signed input (-32768) and maximum signed input (32767).
4. INT4 / INT8 rounding ties.
5. Positive saturation and negative endpoint cases.
6. Error budget equal to the INT4 bound.
7. Error budget one Q30 unit below and above the bound.
8. INT4 rejected but INT8 accepted.
9. Both reduced modes rejected, forcing exact INT16.
10. Repeated operations until the error budget is nearly exhausted.
11. Frame reset and new accumulation window.
12. Accumulator positive and negative overflow boundaries.
13. Reset during idle and reset around valid transactions.
14. Random valid/ready stalls.

## 4. Assertions / formal properties

Candidate properties:
- A reduced-precision transaction is accepted only if its bound fits the remaining budget.
- `error_spent_q30` is monotonic within an accumulation window.
- `error_spent_q30 <= error_budget_q30` whenever the window is active and no reset/reconfiguration exception applies.
- INT16 contributes zero quantization-error bound.
- `frame_start` resets accumulator and error-spent state according to the specified protocol.
- Every accepted input transaction produces exactly one corresponding accumulation update.
- No output transaction is asserted without a corresponding accepted input or defined flush event.

Properties must be written against the final handshake and pipeline specification.

## 5. Randomized testing

Randomize:
- Operand signs and magnitudes.
- Precision budget.
- Accumulation length.
- Mode transitions.
- Valid/ready stalls.
- Reset timing.
- Values near quantization and saturation boundaries.

Use reproducible seeds and archive failing seeds.

## 6. Coverage

Functional coverage should include:
- Every selected precision mode.
- Every transition between modes.
- Budget-near-zero, budget-exact-fit and budget-insufficient cases.
- Operand magnitude bins.
- Positive/negative operand combinations.
- Saturation and rounding events.
- Accumulator overflow and no-overflow cases.
- Frame lengths and handshake stalls.

## 7. Signoff evidence

A verification release requires:
- Python model unit tests.
- RTL simulation regression summary.
- Assertion results.
- Formal proof logs for supported properties.
- Functional coverage report.
- Tool versions and exact commands.
- Archived waveforms for representative corner cases.
