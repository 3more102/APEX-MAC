# APEX-MAC Baseline Architecture

**Status:** first functional single-lane prototype committed; this document describes the current implementation, not a PPA-optimized architecture.

## 1. Numeric representation

Inputs are signed 16-bit two's-complement Q1.15 raw integers:

    a = A / 2^15, b = B / 2^15

| Mode | Operand representation | Real-value quantization step |
|---|---|---:|
| INT4 | signed Q1.3 | 2^-3 |
| INT8 | signed Q1.7 | 2^-7 |
| INT16 | exact signed Q1.15 | 0 |

INT4 and INT8 use round-to-nearest, ties-to-even, followed by saturation to the signed p-bit representable range. Quantized values are re-aligned to Q1.15 before multiplication.

The product is an integer in Q2.30 units. The accumulator is signed 48-bit Q2.30 with sticky overflow detection. On overflow, the prototype holds the accumulator until the next frame reset. The numerical error guarantee applies only to frames without accumulator overflow.

## 2. Conservative product-error bound

For reduced precision p, let Delta_p = 2^(-(p-1)). The conservative operand error is bounded by |delta_a| <= Delta_p and |delta_b| <= Delta_p, including saturation endpoints.

For a_q = a + delta_a and b_q = b + delta_b:

    |a*b - a_q*b_q| <= |a|*Delta_p + |b|*Delta_p + Delta_p^2

For Q1.15 raw integer operands A and B, the corresponding Q30 integer bound is:

    E_op_Q30 = (|A| + |B|)*2^(16-p) + 2^(32-2p)

Therefore:
- INT4: E4 = (|A| + |B|)*2^12 + 2^24.
- INT8: E8 = (|A| + |B|)*2^8 + 2^16.
- INT16: E16 = 0.

For an accumulation window without accumulator overflow, the triangle inequality gives:

    |S_exact - S_approx| <= sum_i E_op_i

The RTL tracks this conservative sum in error_spent_q30.

## 3. Precision-selection policy

For every accepted input transaction:
1. Estimate the INT4 bound.
2. Select INT4 if its bound is less than or equal to the remaining budget.
3. Otherwise select INT8 if its bound fits.
4. Otherwise select exact INT16.
5. Add the selected reduced-mode bound to the error-spent counter. INT16 adds zero.

The budget comparison is inclusive at the boundary. The budget is intended to remain constant throughout a frame. If the external budget is reduced below already-spent error, the RTL selects exact mode and raises sticky budget_violation on the next accepted transaction.

## 4. Implemented RTL partition

| File / module | Responsibility |
|---|---|
| operand_quantizer.sv | Mode-local constants, ties-to-even rounding, saturation and Q1.15 re-alignment |
| error_bound_estimator.sv | Compute INT4 / INT8 Q30 bounds |
| precision_controller.sv | Choose lowest precision within remaining budget |
| precision_tiled_multiplier.sv | Optional radix-16 digit-tiled datapath with 16 signed 5×5 partial-product multipliers |
| apex_mac_top.sv | MAC, optional transaction-qualified multiplier operand isolation, accumulator and status |

The default datapath uses one inferred signed 16×16 multiplier with a 32-bit product. The optional tiled datapath uses sixteen signed 5×5 multipliers with 9-bit partial products. Both are selected by USE_TILED_MULTIPLIER and have passed the same directed and randomized testbenches.

The top-level parameter ENABLE_OPERAND_ISOLATION defaults to 0. When enabled, the multiplier inputs are driven to zero unless a transaction is accepted. This adds 32 generic mapped cells in the current Yosys 0.52 comparison (5,457 baseline versus 5,489 isolated) and reduced multiplier-input bit toggles by 88.73% in the deterministic idle-heavy RTL activity trace. This is not a measured power reduction; see OPERAND_ISOLATION_EXPERIMENT.md.

The precision-tiled variant explicitly activates one radix-16 digit for INT4, two for INT8 and all four for INT16. It currently costs 3.63% more generic mapped cells than the inferred baseline; see MULTIPLIER_VARIANTS.md. This is a prototype trade-off, not an established PPA win.

## 5. Top-level interface and protocol

Top-level parameters:
- ENABLE_OPERAND_ISOLATION (default 0)
- USE_TILED_MULTIPLIER (default 0)

Inputs:
- clk, active-low asynchronous rst_n
- frame_start
- in_valid
- signed operand_a[15:0], operand_b[15:0]
- unsigned error_budget_q30[47:0]

Outputs:
- in_ready
- registered one-cycle out_valid
- signed accumulator_q30[47:0]
- error_spent_q30[47:0]
- last_precision[1:0] (00=INT4, 01=INT8, 10=INT16)
- sticky overflow
- sticky budget_violation

A transaction is accepted when in_valid && in_ready. in_ready is low during reset and while frame_start is asserted. frame_start has priority, clears the accumulator, error counter and sticky status, and suppresses input acceptance in that cycle. out_valid pulses for one cycle after each accepted input. The accumulator/status are continuously visible; there is no output-ready/back-pressure interface.

## 6. Verification and physical-design questions

The repository currently has:
- Python reference-model unit tests.
- Directed Icarus Verilog RTL tests.
- A deterministic randomized RTL regression checking 264 transactions against independent SystemVerilog reference functions.
- The same directed and randomized tests with operand isolation enabled.
- A VCD activity experiment comparing baseline and operand-isolated multiplier inputs.
- A bindable SVA checker; formal execution is still pending.
- A generic Yosys 0.52 synthesis comparison of all four configurations with archived pre/post-synthesis netlists and statistics.

These are functional and generic-synthesis results, not formal proof, ASIC PPA, FPGA-board implementation or signoff evidence.

Next required work:
- Run the SVA checker with a supported formal-capable tool and archive proof assumptions/results.
- Implement a structurally segmented / precision-gated multiplier as a separate variant.
- Compare all variants under identical workloads, synthesis settings and timing constraints.
- Add switching activity and power estimation using technology-mapped netlists and realistic activity annotation.
- Complete FPGA implementation on a selected board.
- Complete ASIC synthesis and OpenROAD RTL-to-GDSII with timing, DRC and LVS evidence.
- Evaluate fixed-point inference workloads and application-level accuracy.
