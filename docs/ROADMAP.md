# APEX-MAC Development Roadmap

**Planning horizon:** 9 months from project start. Calendar dates are to be fixed after tool and FPGA-board availability are confirmed.

| Phase | Duration | Main work | Exit evidence |
|---|---:|---|---|
| 0. Repository and requirements | 1 week | Freeze formats, interfaces, coding and reproducibility rules | Approved specification |
| 1. Literature and novelty | 3 weeks | Read closest work, patents and available RTL | Literature matrix and go/no-go decision |
| 2. Mathematical model | 3 weeks | Python model, error-bound derivation and edge cases | Independently validated model |
| 3. RTL baseline | 4 weeks | Quantizer, estimator, tracker, multiplier and accumulator | Simulation-clean baseline |
| 4. Verification | 4 weeks | Directed/random tests, assertions, formal properties and coverage | Regression and formal reports |
| 5. Datapath optimization | 4 weeks | Segmented multiplier, operand isolation and pipeline study | Measured RTL variants |
| 6. FPGA implementation | 4 weeks | Board constraints, synthesis, place/route and hardware tests | Bitstream, timing and resource reports |
| 7. ASIC RTL-to-GDSII | 6 weeks | Synthesis, floorplan, PDN, placement, CTS, routing, STA, DRC/LVS | Reproducible GDSII and verification reports |
| 8. Workload evaluation | 3 weeks | Fixed-point DNN/DSP traces, error and PPA comparisons | Benchmark database and figures |
| 9. Paper and release | 4 weeks | Manuscript, reproducibility package and submission | Submission-ready manuscript and artifact |

## Phase gates

### Gate A — Novelty
Proceed only when the closest prior work has been read and the research gap is defensible.

### Gate B — Mathematical correctness
The Q30 estimator must be independently validated against exact integer arithmetic, including signed endpoints, ties and saturation.

### Gate C — RTL correctness
Directed tests, randomized regression and required assertions must pass. Formal properties must establish budget safety under explicit assumptions.

### Gate D — Hardware benefit
The precision-scalable implementation must demonstrate a measured advantage over exact INT16 under matched conditions. If not, revise the datapath or research question.

### Gate E — ASIC physical closure
Require positive setup and hold margins under documented constraints, zero unresolved DRC/LVS violations and archived tool logs.

### Gate F — Publication readiness
Every paper claim must map to reproducible scripts, raw results, tool configurations and a clear comparison with prior work.

## First implementation milestone

Start with one verified MAC lane:
- exact INT16 reference mode,
- INT4 and INT8 quantization,
- conservative error estimation,
- budget-safe precision selection,
- overflow detection,
- Python golden model,
- directed and randomized tests.

Do not begin a full multi-lane accelerator until this baseline passes.
