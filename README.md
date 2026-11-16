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

> Status: the first single-lane RTL prototype and Python golden model are committed on `research/reference-model-rtl-foundation`. CI has passed the Python reference-model suite, directed Icarus RTL smoke test, and deterministic randomized RTL regression (264 transactions). A bindable SVA checker has been authored but has not yet been executed by a formal engine. The generic Yosys 0.52 synthesis baseline has passed CI: 5,467 generic mapped cells, with pre/post-synthesis reports archived. This is a logic-count baseline, not ASIC PPA. This is not PPA, FPGA-board, ASIC physical-design, or formal-proof evidence. Novelty remains a hypothesis pending full-text prior-art review.

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
│   ├── PRIOR_ART_MATRIX.md
│   ├── RESEARCH_PLAN.md
│   ├── ROADMAP.md
│   └── VERIFICATION_PLAN.md
├── rtl/                 # Initial single-lane SystemVerilog prototype
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
| RTL implementation | Functional prototype committed |
| Directed RTL simulation | Passing |
| Randomized RTL regression | Passing; 264 checked transactions |
| Operand-isolation variant | Implemented; 88.73% fewer multiplier-input bit toggles in tested trace |
| SVA checker | Authored; formal execution pending |
| Generic Yosys synthesis | Passing; baseline 5,467 cells, isolated 5,500 cells |
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
python experiments/run_precision_sweep.py --samples 10000
```

Development work is isolated on [research/reference-model-rtl-foundation](https://github.com/3more102/APEX-MAC/tree/research/reference-model-rtl-foundation). Do not merge into `main` until the design review and verification gates are satisfied.

## Research integrity

All performance claims must be supported by reproducible reports. Generic Yosys cell counts are not ASIC standard-cell area, timing, power or signoff evidence. FPGA resource counts must not be compared directly with ASIC cell area. ASIC PPA claims must state the PDK, process corner, voltage, temperature, clock constraint, activity assumptions and physical-design stage. A GDSII file alone is not evidence of signoff; DRC, LVS and timing evidence must accompany it.
