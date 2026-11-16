# APEX-MAC

**Adaptive Precision and Error-Budgeted Multiply–Accumulate Accelerator**

APEX-MAC is a research-oriented digital design project investigating a precision-scalable fixed-point MAC whose runtime controller enforces a configured numerical-error budget across an accumulation window.

Targets:
- Synthesizable SystemVerilog RTL.
- Simulation, assertions and formal verification.
- FPGA implementation.
- ASIC RTL-to-GDSII using an open PDK and open-source physical-design flow.
- Reproducible numerical, workload and PPA evaluation.
- A research-paper submission, subject to a demonstrated novelty gap.

> **Research status:** Initial repository and reference-model stage. No RTL, FPGA, ASIC, power, timing, area or GDSII results are claimed.

## Candidate research contribution

A runtime controller estimates a conservative bound on product error for each candidate precision. It chooses the lowest supported precision that fits the remaining error budget for the current accumulation window. If neither reduced-precision mode fits, it uses exact INT16 arithmetic.

The candidate contribution is not simply variable precision. It is the combination of:
1. Operand-dependent product-error bounds.
2. Explicit accumulation-window error-budget accounting.
3. Deterministic precision fallback.
4. Formal verification of budget safety under stated arithmetic assumptions.
5. Matched FPGA and ASIC evaluation.

This is a **candidate research direction**, not a verified novelty claim. Recent work already covers adaptive-precision MACs, runtime energy-aware MACs, and overflow-driven dynamic precision. See [the literature review](docs/LITERATURE_REVIEW.md). The novelty gate must be passed before claiming a new architecture.

## Initial arithmetic contract

- Input operands: signed 16-bit two's-complement Q1.15.
- Reduced modes: signed Q1.3 (INT4) and Q1.7 (INT8).
- Exact mode: signed Q1.15 (INT16).
- Quantization: round-to-nearest, ties-to-even, then saturation.
- Product / accumulator scale: Q2.30.
- Initial accumulator width: signed 48-bit.
- Error budget: non-negative integer in Q30 product units, per accumulation window.
- INT16 contributes zero quantization-error bound.
- Accumulator overflow is detected; the numerical error guarantee applies only when overflow does not occur.

For precision p in {4, 8}, let A and B be the signed Q1.15 integer operands. With a conservative operand quantization error of one reduced-format LSB, the proposed product-error bound in Q30 integer units is:

    E_p(A,B) = (|A| + |B|) * 2^(16-p) + 2^(32-2p)

The bound and implementation are defined in [the architecture specification](docs/ARCHITECTURE.md) and exercised by the Python reference model.

## Repository map

    APEX-MAC/
    ├── .github/workflows/      # Reference-model CI
    ├── docs/                   # Research, architecture and verification plans
    ├── model/                  # Independent Python reference model
    ├── tests/                  # Reference-model unit tests
    ├── rtl/                    # SystemVerilog implementation (next stage)
    ├── formal/                 # Formal properties and harnesses (planned)
    ├── tb/                     # RTL testbenches (planned)
    ├── fpga/                   # FPGA constraints and implementation (planned)
    ├── asic/                   # Synthesis and physical-design flow (planned)
    ├── scripts/                # Reproducible experiment scripts
    ├── experiments/            # Workloads, logs and measured results
    └── paper/                  # Manuscript and figures (planned)

## Initial toolchain candidates

| Stage | Candidate |
|---|---|
| RTL | SystemVerilog |
| Simulation | Questa, Verilator or Icarus Verilog |
| Assertions / formal | SVA, SymbiYosys |
| Reference model | Python 3.11+ (standard library) |
| FPGA | AMD Vivado or Intel Quartus; board to be selected |
| ASIC synthesis | Yosys / ABC |
| Physical design | OpenROAD-flow-scripts |
| Timing | OpenSTA |
| Layout inspection / verification | KLayout, Magic, Netgen |
| Initial open PDK | SkyWater SKY130 HD |

The FPGA board, ASIC PDK corner, timing constraints and tool versions must be frozen before benchmark runs.

## Development status

| Workstream | Status |
|---|---|
| Repository foundation | Initialized |
| Literature / novelty assessment | Preliminary; open |
| Mathematical reference model | Initial implementation |
| RTL architecture | Baseline specification |
| Synthesizable RTL | Not started |
| Simulation / formal verification | Not started |
| FPGA implementation | Not started |
| ASIC RTL-to-GDSII | Not started |
| Workload-level evaluation | Not started |
| Paper | Not started |

## Research integrity

All performance claims must be supported by reproducible reports and exact tool configurations. FPGA LUT/FF counts must not be compared directly with ASIC standard-cell area. ASIC PPA claims must identify the PDK, process corner, voltage, temperature, clock constraints, activity assumptions and physical-design stage. A GDSII file alone is not signoff evidence; DRC, LVS and timing evidence must accompany it.
