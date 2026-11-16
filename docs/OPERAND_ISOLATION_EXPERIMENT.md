# APEX-MAC Operand-Isolation Experiment

## Objective

Measure whether transaction-qualified operand isolation reduces switching activity at the multiplier inputs during idle cycles, and quantify the generic logic-count overhead.

This is an RTL activity experiment, not a power or energy measurement.

## RTL variants

- Baseline: ENABLE_OPERAND_ISOLATION = 0. The multiplier inputs follow the quantized operands even when in_valid is low.
- Operand-isolated: ENABLE_OPERAND_ISOLATION = 1. The multiplier inputs are driven to zero unless an input transaction is accepted.

Both variants use the same signed 16×16 multiplier, arithmetic policy, error estimator, controller, accumulator, and interface.

## Deterministic stimulus

Each variant receives the same fixed-seed operand sequence:
- 256 idle cycles with changing operands and in_valid = 0.
- 64 active cycles with in_valid = 1.
- 256 idle cycles with changing operands and in_valid = 0.

Total: 576 sampled cycles, including 64 accepted MAC transactions. The configured error budget is zero, selecting exact INT16 for accepted operations.

## Results

<badge color="success">88.73% fewer multiplier-input bit toggles</badge>

| Metric | Baseline | Operand-isolated |
|---|---:|---:|
| Operand A bit toggles | 4,617 | 524 |
| Operand B bit toggles | 4,664 | 522 |
| Combined multiplier-input bit toggles | 9,281 | 1,046 |
| Combined vector transitions | 1,152 | 130 |
| Generic mapped cells | 5,467 | 5,500 |

The input-toggle reduction is:

    (9281 - 1046) / 9281 × 100 = 88.73%

Generic mapped cell count increases by 33 cells, approximately 0.60%, for this variant.

## Reproducibility

- CI run: https://github.com/3more102/APEX-MAC/actions/runs/43924955652
- Activity traces and CSV artifact: https://github.com/3more102/APEX-MAC/actions/runs/43924955652/artifacts/14256385551
- Generic synthesis artifact: https://github.com/3more102/APEX-MAC/actions/runs/43924955652/artifacts/14255373015
- Testbench: tb/tb_apex_mac_activity.sv
- VCD analysis: scripts/analyze_operand_activity.py
- Runner: scripts/run_activity_comparison.sh

Re-run locally with:

    make activity-test

## Interpretation and limitations

The result demonstrates reduced switching **at the multiplier input ports** for this specific idle-heavy trace. It does not prove an 88.73% reduction in multiplier internal switching, dynamic power, total chip power, or energy per MAC.

Actual power depends on internal gate activity, glitches, capacitance, clocking, cell selection, placement, routing, voltage and frequency. A later power study must use a technology-mapped netlist, realistic activity annotation (SAIF/VCD), a documented standard-cell library and physical-design conditions.

The extra 33 generic mapped cells are a small logic-count overhead, not a foundry area estimate. Keep the baseline and operand-isolated variants as separate comparison points in subsequent ASIC and FPGA evaluation.
