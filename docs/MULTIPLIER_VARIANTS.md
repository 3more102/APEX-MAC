# APEX-MAC Multiplier Architecture Comparison

## Implemented variants

The top-level supports two orthogonal parameters:

- ENABLE_OPERAND_ISOLATION: drive multiplier inputs to zero when no transaction is accepted.
- USE_TILED_MULTIPLIER: select the radix-16 digit-tiled partial-product implementation instead of the inferred signed 16×16 multiplier.

This creates four reproducible configurations:

| Variant | Operand isolation | Multiplier |
|---|---|---|
| baseline | Off | Inferred signed 16×16 |
| operand_isolated | On | Inferred signed 16×16 |
| tiled | Off | 16 signed 5×5 digit multipliers |
| tiled_isolated | On | 16 signed 5×5 digit multipliers |

## Functional verification

The directed and randomized testbenches are run against all four configurations. Each randomized run checks 264 transactions against an independent reference implementation, including INT4, INT8 and exact INT16 decisions, signed products, error budgets, frame resets, overflow and budget-violation behavior.

Latest verified CI run: https://github.com/3more102/APEX-MAC/actions/runs/43927110271

All four configurations passed the directed and randomized RTL regressions. Each configuration completed 264 randomized accepted transactions (1,056 randomized transactions total). The standalone tiled multiplier also passed 75,792 product checks: all 256 INT4 code pairs, all 65,536 INT8 code pairs, and 10,000 deterministic random INT16 pairs.

The exhaustive multiplier regression is implemented in tb/tb_precision_tiled_multiplier_exhaustive.sv and runs as part of make rtl-test.

## Generic synthesis comparison

Tool: Yosys 0.52, same generic synthesis script, top-level interface and constraints (no PDK library).

| Variant | Generic mapped cells | Wires | Wire bits |
|---|---:|---:|---:|
| baseline | 5,457 | 5,326 | 6,711 |
| operand_isolated | 5,489 | 5,358 | 6,743 |
| tiled | 5,655 | 5,541 | 7,112 |
| tiled_isolated | 5,678 | 5,560 | 7,071 |

Pre-synthesis multiplier audit:

| Variant | Multiplier structure |
|---|---|
| baseline | 1 × signed 16×16 → 32 |
| operand_isolated | 1 × signed 16×16 → 32 |
| tiled | 16 × signed 5×5 → 9 |
| tiled_isolated | 16 × signed 5×5 → 9 |

Relative to the inferred baseline:
- Operand isolation adds 32 generic mapped cells (+0.59%).
- The tiled implementation adds 198 generic mapped cells (+3.63%).
- Tiled plus operand isolation adds 221 generic mapped cells (+4.05%).

The count differences are generic mapped logic statistics, not standard-cell area or physical PPA.

## Interpretation

The tiled design makes precision-dependent digit activation explicit and decomposes the product into 16 smaller signed partial-product multipliers. It is functionally verified, but the generic mapped cell count is higher than the inferred 16×16 baseline.

The operand-isolation experiment previously measured 88.73% fewer bit toggles at the multiplier input ports for an idle-heavy trace. That result does not establish a corresponding power reduction and does not yet measure internal partial-product switching in the tiled architecture.

## Next experiments

1. Measure VCD/SAIF activity for each partial-product tile under INT4, INT8 and INT16 workloads.
2. Compare switching activity at the multiplier inputs and partial-product outputs.
3. Run technology-mapped synthesis and post-route power analysis with a fixed PDK and constraints.
4. Evaluate whether a shared or hierarchical tile architecture can reduce the area overhead while preserving precision-dependent activity savings.

No architecture should be selected as the final research contribution until mapped area, timing, switching/power and workload-level accuracy have been compared under matched conditions.
