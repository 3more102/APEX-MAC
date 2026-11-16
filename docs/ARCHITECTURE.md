# APEX-MAC Baseline Architecture

**Status:** Proposed baseline specification. Freeze after model review and novelty gate.

## 1. Numeric representation

Inputs are signed 16-bit two's-complement Q1.15 integers. If the stored input is A, its real value is A / 2^15.

| Mode | Operand format | Fraction bits | Quantization step |
|---|---|---:|---:|
| INT4 | signed Q1.3 | 3 | 2^-3 |
| INT8 | signed Q1.7 | 7 | 2^-7 |
| INT16 | signed Q1.15 | 15 | 2^-15 |

INT16 is the exact reference mode. Reduced modes use round-to-nearest, ties-to-even, followed by saturation to the signed destination range.

All quantized operands are expanded back to the common Q1.15 raw-integer scale before multiplication. Products therefore share a Q2.30 raw-integer representation.

The initial accumulator is signed 48-bit Q-format with Q30 fractional scaling. Overflow must be detected and reported. The error-budget guarantee is conditional on no accumulator overflow.

## 2. Conservative product-error bound

For reduced precision p in {4, 8}, the conservative real operand error is bounded by:

    |delta_a|, |delta_b| <= Delta_p, where Delta_p = 2^(1-p)

This is a conservative one-LSB bound that includes saturation at the positive endpoint. For a_q = a + delta_a and b_q = b + delta_b:

    |a*b - a_q*b_q| <= |a|*Delta_p + |b|*Delta_p + Delta_p^2

With raw Q1.15 integers A and B, the corresponding bound in Q30 integer units is:

    E_p_Q30(A,B) = (|A| + |B|) * 2^(16-p) + 2^(32-2p)

For INT16, E_16_Q30 = 0.

The Python reference model is the executable definition of the initial quantization and bound behavior. Any change to rounding, saturation or format must update both the model and specification.

## 3. Accumulation-level contract

For a window of N MAC operations, the accumulated absolute arithmetic error is bounded by the sum of the per-operation bounds:

    |S_exact - S_approx| <= sum(E_p_i_Q30(A_i,B_i)) for i = 0 ... N-1

The controller maintains error_spent_q30 and never admits a reduced-precision operation whose bound exceeds the remaining configured budget.

The guarantee does not cover accumulator overflow, input errors, analog noise, model quantization outside this MAC, or other unmodeled effects.

## 4. Precision-selection policy

For each accepted operand pair:
1. Compute the INT4 error bound.
2. If it is less than or equal to the remaining budget, select INT4.
3. Otherwise compute/check the INT8 bound.
4. If it fits, select INT8.
5. Otherwise select exact INT16.
6. Add the selected operation's bound to the accumulated error counter.
7. INT16 adds zero to the error counter.

The boundary is inclusive. A new accumulation window resets the accumulator and error counter atomically.

## 5. Proposed RTL partition

| Module | Responsibility |
|---|---|
| apex_mac_top | Top-level interface, configuration and status |
| precision_controller | Select INT4 / INT8 / INT16 |
| error_bound_estimator | Estimate conservative product-error bound |
| error_budget_tracker | Track spent and remaining budget |
| operand_quantizer | Round and saturate operands |
| precision_scalable_multiplier | Mode-dependent multiplication |
| product_aligner | Common Q2.30 product representation |
| accumulator | 48-bit accumulation and overflow detection |
| register_bank | Control, status and counters |

The exact module boundaries may change after timing and area profiling.

## 6. Interface contract to freeze before RTL

Candidate inputs:
- clk, rst_n
- in_valid, in_ready
- frame_start
- operand_a[15:0], operand_b[15:0]
- error_budget_q30[47:0]

Candidate outputs:
- out_valid
- accumulator_q30[47:0]
- error_spent_q30[47:0]
- last_precision[1:0]
- overflow
- budget_violation

The final handshake, pipeline latency, reset semantics, budget reconfiguration rules and frame-start priority must be specified before implementation.

## 7. Physical implementation risk

A behavioral case statement around 4-, 8- and 16-bit multiplications may synthesize into a full-width multiplier and fail to deliver the expected area or power benefit.

Compare:
- A straightforward inferred-multiplier baseline.
- A structurally segmented / gated partial-product implementation.
- A resource-shared implementation if throughput permits.

Do not infer energy savings from RTL structure alone. Measure switching activity and post-route implementation results.
