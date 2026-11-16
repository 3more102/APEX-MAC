# APEX-MAC RTL

## Implemented modules

| File | Function |
|---|---|
| operand_quantizer.sv | Signed Q1.15 quantization with ties-to-even rounding and saturation |
| error_bound_estimator.sv | Computes conservative INT4 and INT8 product-error bounds in Q30 integer units |
| precision_controller.sv | Selects INT4, INT8 or exact INT16 from the remaining frame budget |
| precision_tiled_multiplier.sv | Optional radix-16 multiplier using sixteen signed 5×5 partial-product multipliers |
| apex_mac_top.sv | Single-lane MAC, selectable multiplier, optional operand isolation, accumulator and status outputs |

## Top-level parameters

- ENABLE_OPERAND_ISOLATION = 0 by default. When enabled, multiplier inputs are held at zero unless a transaction is accepted.
- USE_TILED_MULTIPLIER = 0 by default. When enabled, the radix-16 digit-tiled multiplier is selected instead of the inferred signed 16×16 multiplier.

## Current interface behavior

- One input transaction is accepted when in_valid && in_ready.
- in_ready is low during reset and frame_start.
- frame_start clears the accumulator, error-spent counter and sticky status.
- out_valid is a one-cycle registered pulse for each accepted transaction.
- The accumulator and status are continuously visible; there is no output back-pressure.
- Keep error_budget_q30 constant for a frame. Lowering it below already-spent error raises sticky budget_violation.
- Accumulator overflow raises sticky overflow and holds the accumulator until the next frame reset.

## Architecture comparison

All four combinations of native/tiled multiplier and operand isolation pass the directed and randomized regressions. Each randomized regression checks 264 accepted transactions against independent reference functions. The tiled multiplier additionally passes 75,792 product checks: exhaustive INT4 and INT8 code pairs plus 10,000 random INT16 pairs.

Yosys 0.52 generic mapped counts:
- Native multiplier: 5,457 cells.
- Native + operand isolation: 5,489 cells.
- Tiled multiplier: 5,655 cells.
- Tiled + operand isolation: 5,678 cells.

The tiled variant has sixteen 5×5 multipliers and adds 3.63% generic mapped cells over the native baseline. The operand-isolation variant adds 0.59% generic mapped cells. These are generic logic counts, not ASIC area or PPA.

For the native multiplier, the deterministic 576-cycle idle-heavy trace reduced multiplier-input bit toggles from 9,281 to 1,046 (88.73%) with operand isolation enabled. This is an RTL input-activity proxy, not a power measurement. See docs/OPERAND_ISOLATION_EXPERIMENT.md and docs/MULTIPLIER_VARIANTS.md.

## Current limitations

- The tiled multiplier is a functional research variant, not yet an area-optimized or power-validated implementation.
- No pipeline, multiple MAC lanes, bus register interface, clock gating or DSP-aware FPGA specialization has been implemented.
- No formal proof, PPA, FPGA-board, ASIC physical-design, DRC/LVS or GDSII result is claimed.

## Run regressions

From the repository root, with Icarus Verilog installed:

    make rtl-test

This runs directed and randomized tests for all four multiplier/isolation configurations, then performs the VCD activity comparison.
