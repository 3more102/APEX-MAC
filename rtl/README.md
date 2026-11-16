# APEX-MAC RTL

## Implemented modules

| File | Function |
|---|---|
| `operand_quantizer.sv` | Module-local signed Q1.15 quantization with ties-to-even rounding and saturation |
| `error_bound_estimator.sv` | Computes conservative INT4 and INT8 product-error bounds in Q30 integer units |
| `precision_controller.sv` | Selects INT4, INT8 or exact INT16 from the remaining frame budget |
| `apex_mac_top.sv` | Single-lane MAC, accumulator, error-spent state and status outputs |

## Current interface behavior

- One input transaction is accepted when `in_valid && in_ready`.
- `in_ready` is low during reset and `frame_start`.
- `frame_start` clears the accumulator, error-spent counter and sticky status.
- `out_valid` is a one-cycle registered pulse for each accepted transaction.
- The accumulator and status are continuously visible; there is no output back-pressure.
- Keep `error_budget_q30` constant for a frame. Lowering it below already-spent error raises sticky `budget_violation`.
- Accumulator overflow raises sticky `overflow` and holds the accumulator until the next frame reset.

## Current limitations

- The datapath is a functional precision/accuracy prototype, not yet an area-optimized variable-width multiplier.
- The multiplier is currently one inferred signed 16×16 multiplier with a 32-bit product. The pre-synthesis Yosys netlist confirms A_WIDTH=16, B_WIDTH=16 and Y_WIDTH=32. The optional ENABLE_OPERAND_ISOLATION parameter forces multiplier inputs to zero unless a transaction is accepted. In the deterministic 576-cycle idle-heavy trace, multiplier-input bit toggles fell from 9,281 to 1,046 (88.73%); this is an RTL activity proxy, not a power measurement. The native Yosys frontend uses module-local mode constants and quantizer logic to avoid unsupported package imports. No segmented or precision-gated partial-product architecture has been implemented yet.
- No pipeline, multiple MAC lanes, bus register interface, clock gating, partial-product gating or DSP-aware FPGA specialization has been implemented.
- No PPA, FPGA-board, ASIC physical-design, DRC/LVS or GDSII result is claimed.

## Run RTL smoke test

From the repository root, with Icarus Verilog installed:

```bash
make rtl-test
```

The directed testbench checks key arithmetic and budget boundaries. A second deterministic randomized testbench checks 264 transactions against independent reference functions in both isolation settings. The VCD activity experiment is run with make activity-test.
