# APEX-MAC

**Adaptive Precision and Error-Budgeted Multiply–Accumulate Accelerator**

APEX-MAC is a research-oriented digital design project investigating runtime precision selection for fixed-point multiply–accumulate (MAC) workloads. The target is a reproducible implementation across FPGA and ASIC flows, including RTL verification, synthesis, physical design, and GDSII generation.

## Research direction

The candidate architecture supports signed fixed-point operands and three arithmetic modes:

- **INT4:** reduced-precision operation
- **INT8:** medium-precision operation
- **INT16:** full-precision reference operation

A runtime controller estimates a conservative upper bound on the numerical error introduced by each reduced-precision operation. It selects the lowest precision whose error bound fits within the remaining accumulation error budget; otherwise, it selects INT16.

The research question is whether this **accumulation-level error-budget policy**, combined with a hardware-efficient precision-scalable datapath, can provide a useful energy/area/performance trade-off while enforcing a measurable numerical-error bound.

> Status: the single-lane RTL prototype and Python reference model are implemented. CI passes four configurations (native/tiled multiplier, with/without operand isolation), including 264 randomized transactions per configuration and 75,792 tiled-multiplier product checks. Yosys 0.52 reports 5,457–5,678 generic mapped cells across the four variants. These are functional and generic synthesis results only—not ASIC PPA, FPGA-board results, physical-design signoff or formal proof. The candidate novelty claim remains open pending full-text prior-art review.

## Initial design assumptions

- Input operands: signed 16-bit two's-complement Q1.15.
- Reduced modes: rounded and saturated Q1.3 (INT4) and Q1.7 (INT8).
- Full mode: exact Q1.15 × Q1.15 multiplication (INT16).
- Product alignment: signed Q2.30 representation.
- Accumulator: 48-bit signed, with overflow detection.
- Error budget: accumulated conservative product-error bound in Q30 units.
- Initial evaluation: standalone MAC, followed by vector/DNN workload integration.

These are baseline specification choices and may be revised after modeling and feasibility tests.

## Main research objectives

1. Develop a mathematically defined, error-budget-aware precision-selection policy.
2. Implement a precision-scalable MAC datapath with measurable operand isolation and switching reduction.
3. Verify arithmetic correctness, error-bound safety, and control behavior.
4. Evaluate representative workloads and application-level accuracy.
5. Implement the same RTL on FPGA and through an ASIC RTL-to-GDSII flow.
6. Publish reproducible RTL, scripts, constraints, and benchmark methodology where licensing permits.

## Repository map

```text
APEX-MAC/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── LITERATURE_REVIEW.md
│   ├── GENERIC_SYNTH_BASELINE.md
│   ├── OPERAND_ISOLATION_EXPERIMENT.md
│   ├── MULTIPLIER_VARIANTS.md
│   ├── PRIOR_ART_MATRIX.md
│   ├── RESEARCH_PLAN.md
│   ├── ROADMAP.md
│   └── VERIFICATION_PLAN.md
├── rtl/                 # Native and precision-tiled single-lane SystemVerilog variants
├── tb/                  # Directed and randomized Icarus testbenches
├── tests/               # Python reference-model unit tests
├── formal/              # Bindable SVA checker; formal proof pending
├── scripts/             # Reproducible synthesis and analysis scripts
├── fpga/                # FPGA constraints and implementation
├── asic/                # ASIC RTL-to-GDSII planning and flow
├── models/              # Python reference models
├── experiments/         # Synthetic precision-policy sweep and future measured results
└── paper/               # Manuscript, figures and supplementary material
```

## Planned toolchain

| Stage | Candidate tools |
|---|---|
| RTL | SystemVerilog |
| Simulation | Icarus Verilog (CI), Questa / Verilator (planned) |
| Assertions/formal | SVA, SymbiYosys or Questa Formal |
| Reference model | Python standard library |
| FPGA | AMD Vivado or Intel Quartus (board to be selected) |
| Generic synthesis | Yosys / ABC |
| ASIC physical design | OpenROAD-flow-scripts |
| Timing | OpenSTA |
| Layout inspection / verification | KLayout, Magic, Netgen |
| Initial open PDK | SkyWater SKY130 HD |

Tool versions, FPGA board, PDK corner, clock constraints and libraries must be recorded before benchmark runs.

## Development status

| Workstream | Status |
|---|---|
| Repository foundation | Initial structure committed |
| Literature and novelty assessment | Preliminary; systematic review pending |
| Mathematical reference model | Implemented; unit tests pass in CI |
| RTL architecture | Initial single-lane specification implemented |
| RTL implementation | Native 16×16 and precision-tiled 16×5×5 variants implemented |
| Directed RTL simulation | Passing |
| Randomized RTL regression | Passing; 264 transactions per configuration across four variants |
| Tiled multiplier arithmetic | Passing; 75,792 product checks including exhaustive INT4 and INT8 |
| Operand-isolation variant | Implemented; 88.73% fewer multiplier-input bit toggles in tested trace |
| Precision-tiled multiplier | Implemented; 16 signed 5×5 partial-product multipliers; generic area count +3.63% |
| Combinational arithmetic proof | Added to Yosys SAT CI; result pending |
| Sequential SVA checker | Authored; sequential formal execution pending |
| Generic Yosys synthesis | Passing; four variants, 5,457–5,678 generic cells |
| FPGA implementation | Not started |
| ASIC RTL-to-GDSII | Not started |
| Paper | Not started |

## Quick checks

```bash
make model-test   # Python golden-model tests
make rtl-test     # Directed + randomized Icarus RTL regressions
make test         # Run all standard checks
bash scripts/run_generic_synth.sh
make activity-test       # VCD-based multiplier input-toggle comparison
make formal-test         # Yosys SAT arithmetic-bound proof
python experiments/run_precision_sweep.py --samples 10000
```

Development work is isolated on [research/reference-model-rtl-foundation](https://github.com/3more102/APEX-MAC/tree/research/reference-model-rtl-foundation). Do not merge into `main` until the design review and verification gates are satisfied.

## Research integrity

All performance claims must be supported by reproducible reports. Generic Yosys cell counts are not ASIC standard-cell area, timing, power or signoff evidence. FPGA resource counts must not be compared directly with ASIC cell area. ASIC PPA claims must state the PDK, process corner, voltage, temperature, clock constraint, activity assumptions and physical-design stage. A GDSII file alone is not evidence of signoff; DRC, LVS and timing evidence must accompany it.
