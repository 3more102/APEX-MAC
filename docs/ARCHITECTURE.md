# APEX-MAC Baseline Architecture

**Status:** proposed specification; subject to reference-model validation.

## 1. Numeric representation

Inputs are signed 16-bit two's-complement Q1.15 values. Let the stored integers be (A) and (B), so the represented real values are (a=A/2^{15}) and (b=B/2^{15}).

Supported precision modes:

| Mode | Quantized operand format | Quantization step |
|---|---|---:|
| INT4 | signed Q1.3 | (2^{-3}) |
| INT8 | signed Q1.7 | (2^{-7}) |
| INT16 | exact signed Q1.15 | 0 error |

INT4 and INT8 use round-to-nearest with saturation. The exact rounding tie rule must be fixed in the reference model and RTL specification (recommended: round-to-nearest, ties-to-even).

Products are aligned to a common Q2.30 scale before accumulation. The initial accumulator width is 48 signed bits. Overflow must be detected; the error-bound guarantee applies only when overflow does not occur.

## 2. Conservative error bound

For a reduced-precision mode with quantization step (Delta_p), use the conservative operand-error bound (|delta_a| leq Delta_p) and (|delta_b| leq Delta_p). This bound accommodates endpoint saturation.

For (a_q=a+delta_a) and (b_q=b+delta_b):

[
|ab-a_qb_q|
leq |a|Delta_p+|b|Delta_p+Delta_p^2.
]

For INT16, the quantization error is zero.

In Q30 integer units, for raw input magnitudes (|A|), (|B|), and (p in {4,8}):

[
E_{op,Q30}
=
(|A|+|B|) cdot 2^{16-p}
+
2^{32-2p}.
]

This expression must be checked against an independent high-precision software model, including minimum-negative operands, rounding ties and saturation endpoints. INT16 contributes zero quantization error.

For a sequence of MAC operations, the conservative accumulated bound is the sum of accepted per-operation bounds:

[
E_{total} leq sum_{i=0}^{N-1} E_{op,i}.
]

The guarantee assumes no accumulator overflow and no unmodeled error source.

## 3. Precision-selection policy

At each accepted MAC input:
1. Compute the INT4 conservative error bound.
2. If it fits within the remaining error budget, select INT4.
3. Otherwise compute/check the INT8 bound.
4. If it fits, select INT8.
5. Otherwise select exact INT16.
6. Add the selected operation's bound to the accumulated error budget.
7. For INT16, add zero.

The exact behavior at a budget boundary is inclusive: an operation is accepted in a reduced mode when its bound is less than or equal to the remaining budget.

The policy must never allow the accumulated bound to exceed the configured budget. A new accumulation window resets the accumulated error counter and MAC accumulator together.

## 4. Proposed RTL partition

| Module | Responsibility |
|---|---|
| `apex_mac_top` | Top-level valid/ready, configuration and status |
| `precision_controller` | Select INT4 / INT8 / INT16 |
| `error_bound_estimator` | Compute conservative per-operation bound |
| `error_budget_tracker` | Track budget spent and remaining |
| `operand_quantizer` | Round and saturate operands |
| `precision_scalable_multiplier` | Mode-dependent multiplication |
| `product_aligner` | Align products to Q2.30 |
| `accumulator` | 48-bit signed accumulation and overflow detection |
| `register_bank` | Control, status and performance counters |

Module boundaries may be changed after timing and area profiling.

## 5. Top-level transaction concept

Inputs:
- `clk`, `rst_n`
- `in_valid`, `in_ready`
- `frame_start`
- `operand_a[15:0]`, `operand_b[15:0]`
- `error_budget_q30`
- `accumulate_enable`

Outputs:
- `out_valid`
- `accumulator_q30[47:0]`
- `error_spent_q30[47:0]`
- `last_precision[1:0]`
- `overflow`
- `budget_violation`

The final interface protocol, pipeline latency, reset semantics and back-pressure behavior must be specified before RTL coding.

## 6. Physical implementation question

A behavioral case statement around 4-, 8- and 16-bit multiplications may synthesize into a full-width multiplier and fail to deliver the expected power or area advantage. The implementation must therefore compare:
- A straightforward inferred-multiplier baseline.
- A structurally segmented / gated partial-product implementation.
- Any resource-shared alternative that meets throughput requirements.

Report post-synthesis and post-route results. Do not infer power savings from RTL structure alone.
