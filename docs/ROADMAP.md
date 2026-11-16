# APEX-MAC Development Roadmap

**Planning horizon:** 9 months. Dates are provisional and should be adjusted to the actual start date and tool availability.

| Phase | Duration | Main work | Exit evidence |
|---|---:|---|---|
| 0. Repository and requirements | 1 week | Freeze interfaces, coding rules, reproducibility policy | Approved specification |
| 1. Literature and novelty | 3 weeks | Review closest MAC, approximate-computing and error-control work | Literature matrix and novelty decision |
| 2. Mathematical model | 3 weeks | Python reference, quantization, error-bound proof and exhaustive edge cases | Independently validated model |
| 3. RTL baseline | 4 weeks | Exact MAC, quantizer, estimator, budget tracker, integration | Simulation-clean baseline |
| 4. Verification | 4 weeks | Directed/random tests, assertions, formal properties, coverage | Regression and formal reports |
| 5. Datapath optimization | 4 weeks | Segmented multiplier, operand isolation, pipeline and parameter study | Measured RTL variants |
| 6. FPGA implementation | 4 weeks | Board selection, constraints, synthesis, place/route, hardware test | Bitstream and timing/resource reports |
| 7. ASIC RTL-to-GDSII | 6 weeks | Synthesis, floorplan, PDN, placement, CTS, routing, STA, DRC/LVS | Reproducible GDSII and signoff reports |
| 8. Workload evaluation | 3 weeks | CNN/MLP traces, accuracy/error analysis, PPA comparison | Benchmark database and figures |
| 9. Paper and release | 4 weeks | Manuscript, artifact review, documentation and submission | Submission-ready paper and reproducibility package |

## Phase gates

### Gate A — Novelty
Proceed only when the research gap is distinct from the closest prior publications and patents.

### Gate B — Mathematical correctness
The Q30 error estimator must be independently validated against high-precision calculations for boundary and randomized vectors.

### Gate C — RTL correctness
All directed tests, randomized regressions and required assertions must pass. Formal properties must establish budget safety under stated assumptions.

### Gate D — Hardware benefit
The precision-scalable implementation must show a measured advantage over the exact baseline under matched conditions. If not, revise the datapath or research claim.

### Gate E — ASIC physical closure
Require positive setup/hold margins under documented constraints, zero unresolved DRC/LVS violations, and archived tool logs.

### Gate F — Publication readiness
All claims must map to reproducible scripts, raw results, configuration files and a clear comparison with prior work.

## Initial milestone

The first implementation milestone is not a neural-network accelerator. It is a verified single-lane MAC with:
- exact INT16 reference mode,
- INT4 and INT8 quantization,
- conservative error estimation,
- budget-safe precision selection,
- overflow detection,
- a Python golden model,
- directed and randomized tests.

Only after this passes should the design expand to multiple lanes or workload-level acceleration.
