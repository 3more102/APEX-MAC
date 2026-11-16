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

> Research status: architecture and novelty assessment. No RTL, PPA, FPGA, or GDSII results are claimed yet. Novelty must be established against current literature before publication claims are made.

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
│   ├── RESEARCH_PLAN.md
│   ├── ROADMAP.md
│   └── VERIFICATION_PLAN.md
├── rtl/                 # Synthesizable SystemVerilog (to be implemented)
├── tb/                  # Simulation testbenches (to be implemented)
├── formal/              # Formal properties and harnesses (to be implemented)
├── scripts/             # Reproducible build and analysis scripts
├── fpga/                # FPGA constraints and implementation
├── asic/                # Synthesis, floorplan, P&R and signoff flow
├── models/              # Python/MATLAB reference models
├── experiments/         # Workloads, logs and measured results
└── paper/               # Manuscript, figures and supplementary material
```

## Planned toolchain

| Stage | Candidate tools |
|---|---|
| RTL | SystemVerilog |
| Simulation | Questa, Verilator or Icarus Verilog |
| Assertions/formal | SVA, SymbiYosys |
| Reference model | Python / NumPy |
| FPGA | AMD Vivado or Intel Quartus (board to be selected) |
| ASIC synthesis | Yosys / ABC |
| Physical design | OpenROAD-flow-scripts |
| Timing | OpenSTA |
| Layout inspection / verification | KLayout, Magic, Netgen |
| Initial open PDK | SkyWater SKY130 HD |

Tool versions, FPGA board, PDK corner, clock constraints and libraries must be recorded before benchmark runs.

## Development status

| Workstream | Status |
|---|---|
| Repository foundation | In progress |
| Literature and novelty assessment | In progress |
| Mathematical reference model | Not started |
| RTL architecture | Specified at concept level |
| RTL implementation | Not started |
| Simulation and formal verification | Not started |
| FPGA implementation | Not started |
| ASIC RTL-to-GDSII | Not started |
| Paper | Not started |

## Research integrity

All performance claims must be supported by reproducible reports. FPGA resource counts must not be compared directly with ASIC cell area. ASIC PPA claims must state the PDK, process corner, voltage, temperature, clock constraint, activity assumptions and physical-design stage. A GDSII file alone is not evidence of signoff; DRC, LVS and timing evidence must accompany it.
