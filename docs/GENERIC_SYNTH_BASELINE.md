# APEX-MAC Generic Synthesis Baseline

## Run identification

- Tool: Yosys 0.52 (fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
- Branch: research/reference-model-rtl-foundation
- RTL commit: 55e7d287c9cb13d0ef3b1dd1f65f5336b1b25fef
- Target top: apex_mac_top
- Flow: native SystemVerilog frontend, pre-synthesis stat/netlist, generic synth -flatten, check -assert, post-synthesis stat/netlist
- CI run: https://github.com/3more102/APEX-MAC/actions/runs/43926481440
- Archived reports: https://github.com/3more102/APEX-MAC/actions/runs/43926481440/artifacts/14256301875

## Multiplier-width audit

The native baseline uses one signed 16×16 multiplier with a 32-bit result. The pre-synthesis Yosys netlist confirms A_WIDTH=16, B_WIDTH=16, Y_WIDTH=32, A_SIGNED=1 and B_SIGNED=1.

The precision-tiled variant uses sixteen signed 5×5 multipliers with 9-bit results, one for each pair of radix-16 operand digits. All four variants pass Yosys check -assert.

## Four-variant generic synthesis comparison

**Generic mapped cell counts:**

| Variant | Generic mapped cells | Wires | Wire bits |
|---|---:|---:|---:|
| baseline | 5,457 | 5,326 | 6,711 |
| operand_isolated | 5,489 | 5,358 | 6,743 |
| tiled | 5,655 | 5,541 | 7,112 |
| tiled_isolated | 5,678 | 5,560 | 7,071 |

### Baseline cell breakdown

| Cell type | Count |
|---|---:|
| $_ANDNOT_ | 1,991 |
| $_AND_ | 100 |
| $_DFFE_PN0P_ | 91 |
| $_DFFE_PN1P_ | 1 |
| $_DFF_PN0_ | 1 |
| $_MUX_ | 180 |
| $_NAND_ | 143 |
| $_NOR_ | 523 |
| $_NOT_ | 202 |
| $_ORNOT_ | 289 |
| $_OR_ | 544 |
| $_XNOR_ | 432 |
| $_XOR_ | 957 |
| $scopeinfo | 3 |

### Interpretation

Relative to the native baseline:
- Operand isolation adds 32 generic cells (+0.59%).
- The tiled multiplier adds 198 generic cells (+3.63%).
- Tiled plus operand isolation adds 221 generic cells (+4.05%).

These generic counts are useful for early RTL-variant screening. They are not ASIC standard-cell area, timing, power or signoff results. No PDK library was used. There are no routed parasitics, clock-tree implementation, activity-based power estimates, DRC, LVS or GDSII in this run.

See [MULTIPLIER_VARIANTS.md](MULTIPLIER_VARIANTS.md) for the architecture comparison and [OPERAND_ISOLATION_EXPERIMENT.md](OPERAND_ISOLATION_EXPERIMENT.md) for the separate VCD input-toggle experiment.

## Next comparison

Use the same Yosys version, script and top-level interface for further variants. Keep the reference model and directed/randomized tests unchanged. Compare generic cell counts as an early screening metric, then use a selected PDK and OpenROAD for actual ASIC area, timing and power evaluation.
