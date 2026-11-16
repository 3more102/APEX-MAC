# APEX-MAC Verification Plan

## 1. Objectives

Verify:
- Signed arithmetic in all modes.
- Round-to-nearest, ties-to-even and saturation.
- Product alignment to Q2.30.
- Accumulator arithmetic and overflow detection.
- Precision selection at every error-budget boundary.
- Accumulated error bound never exceeds the configured budget.
- Reset, frame-start, valid/ready and back-pressure behavior.
- No loss, duplication or reordering of accepted transactions.

## 2. Independent reference model

The Python model in model/apex_mac_model.py is independent of the RTL. It uses integer arithmetic and must report:
- Quantized operands.
- Exact and quantized products.
- Per-operation error bound.
- Accumulated exact and approximate results.
- Selected precision and remaining budget.

Do not use the RTL implementation as the golden model.

## 3. Directed test groups

1. Zero operands and zero products.
2. Positive and negative operands.
3. Minimum signed input (-32768) and maximum signed input (32767).
4. INT4 and INT8 rounding ties.
5. Positive saturation and negative endpoint cases.
6. Budget exactly equal to the INT4 bound.
7. Budget one Q30 unit below and above a candidate bound.
8. INT4 rejected but INT8 accepted.
9. Both reduced modes rejected, forcing exact INT16.
10. Repeated operations until the error budget is nearly exhausted.
11. Frame reset and new accumulation window.
12. Positive and negative accumulator overflow boundaries.
13. Reset around valid transactions.
14. Random valid/ready stalls.

## 4. Candidate assertions / formal properties

- A reduced-precision transaction is accepted only if its bound fits the remaining budget.
- error_spent_q30 is monotonic within an accumulation window.
- error_spent_q30 <= error_budget_q30 whenever the window is active.
- INT16 contributes zero quantization-error bound.
- frame_start resets accumulator and error state atomically according to the protocol.
- Every accepted input causes exactly one accumulation update.
- No output is asserted without a corresponding accepted input or specified flush event.
- Overflow is detected and reported; no error guarantee is claimed after overflow.

Properties must be adapted to the final pipeline and handshake specification.

## 5. Randomized testing

Randomize operand signs/magnitudes, error budgets, accumulation lengths, mode transitions, valid/ready stalls, reset timing and values near rounding/saturation boundaries. Use reproducible seeds and archive failing seeds.

## 6. Coverage

Cover every selected precision, every precision transition, exact-fit and insufficient-budget cases, operand magnitude bins, sign combinations, saturation and rounding events, overflow/no-overflow cases, accumulation lengths and handshake stalls.

## 7. Verification release evidence

- Python model tests.
- RTL simulation regression summary.
- Assertion results.
- Formal proof logs for supported properties.
- Functional coverage report.
- Tool versions and exact commands.
- Representative corner-case waveforms.
