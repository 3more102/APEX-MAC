# APEX-MAC Generic Synthesis Baseline

## Run identification

- Tool: Yosys 0.52 (fee39a3284c90249e1d9684cf6944ffbbcbb8f90)
- Branch: research/reference-model-rtl-foundation
- Corrected RTL commit: 81999669e8efb96a074ee8d0d5ee8c21bcae8e8c
- Target top: apex_mac_top
- Flow: native SystemVerilog frontend, pre-synthesis stat/netlist, generic synth -flatten, check -assert, post-synthesis stat/netlist
- CI run: https://github.com/3more102/APEX-MAC/actions/runs/43924023058
- Archived reports: https://github.com/3more102/APEX-MAC/actions/runs/43924023058/artifacts/14254579532

## Multiplier-width audit

The first RTL version explicitly sign-extended each 16-bit quantized operand to 32 bits before multiplication. The pre-synthesis Yosys netlist consequently contained one signed 32×32 multiplier with a 32-bit result.

The RTL was corrected to multiply the original signed 16-bit operands directly. The corrected pre-synthesis netlist confirms:

| Parameter | Corrected result |
|---|---:|
| A_WIDTH | 16 |
| B_WIDTH | 16 |
| Y_WIDTH | 32 |
| A_SIGNED | 1 |
| B_SIGNED | 1 |
| Number of $mul cells | 1 |

This preserves the complete signed 16×16 product in 32 bits without unnecessarily widening the multiplier inputs.

## Corrected generic mapped result

**5,467 generic cells**

| Metric | Result |
|---|---:|
| Generic mapped cells | 5,467 |
| Wires | 5,336 |
| Wire bits | 6,721 |
| Public wires | 53 |
| Public wire bits | 1,343 |
| Ports | 14 |
| Port bits | 186 |
| Memories | 0 |
| Processes after synthesis | 0 |
| Sequential cells | 93 |

### Cell breakdown

| Cell type | Count |
|---|---:|
| $_ANDNOT_ | 1,995 |
| $_AND_ | 101 |
| $_DFFE_PN0P_ | 91 |
| $_DFFE_PN1P_ | 1 |
| $_DFF_PN0_ | 1 |
| $_MUX_ | 180 |
| $_NAND_ | 140 |
| $_NOR_ | 526 |
| $_NOT_ | 223 |
| $_ORNOT_ | 282 |
| $_OR_ | 539 |
| $_XNOR_ | 414 |
| $_XOR_ | 971 |
| $scopeinfo | 3 |

Yosys reported zero problems in the post-synthesis check -assert pass.

## Interpretation

The previous 32×32-inferred version mapped to 5,469 generic cells; the corrected 16×16-input version maps to 5,467. This very small difference indicates that Yosys had already optimized much of the sign extension during technology-independent synthesis. The correction is still important because it makes the intended arithmetic width explicit and removes unnecessary RTL widening.

These generic cell counts are **not ASIC standard-cell area**. No PDK library was used. The results contain no routed parasitics, timing constraints, clock-tree implementation, activity-based power estimate, DRC, LVS or GDSII.

The current design still uses one inferred 16×16 multiplier. Reduced modes quantize and align the operands, but the RTL does not yet instantiate a structurally gated partial-product architecture. No area or energy saving from the precision modes should be claimed.

## Operand-isolation variant

The same Yosys 0.52 script also synthesizes ENABLE_OPERAND_ISOLATION=1:

| Metric | Baseline | Operand-isolated |
|---|---:|---:|
| Generic mapped cells | 5,467 | 5,500 |
| Wires | 5,336 | 5,369 |
| Wire bits | 6,721 | 6,754 |
| Multiplier | signed 16×16 → 32 | signed 16×16 → 32 |

The isolated variant adds 33 generic mapped cells (+0.60%). Both variants preserve one signed 16×16 multiplier. The separate [operand-isolation experiment](OPERAND_ISOLATION_EXPERIMENT.md) measures an 88.73% reduction in bit toggles at the multiplier input ports for a deterministic idle-heavy trace. That is an input-activity proxy, not measured power.

## Next comparison

Use the same Yosys version, script and top-level interface to compare:
1. Current inferred 16×16 multiplier baseline.
2. Operand-isolated multiplier variant.
3. Structurally segmented / precision-gated multiplier variant.

Keep the reference model and all directed/randomized tests unchanged. Compare generic cell counts as an early screening metric, then use the selected PDK and OpenROAD for actual ASIC area, timing and power evaluation.
