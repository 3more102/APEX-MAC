# APEX-MAC Research Plan

## Working title

**APEX-MAC: An Accumulation-Budgeted Precision-Scalable MAC with Runtime Error Contracts**

The title is provisional pending the novelty assessment.

## 1. Problem statement

Fixed-precision MAC units perform all operations at one precision. Precision-scalable MACs offer runtime flexibility, but a selectable precision mode alone does not establish a deterministic bound on accumulated arithmetic error for a particular reduction or dot product.

This project investigates a fixed-point MAC architecture in which each reduced-precision operation is admitted only when a conservative product-error bound fits within the remaining error budget of the current accumulation window. Otherwise, the operation uses exact arithmetic.

## 2. Candidate hypothesis

For supported fixed-point inputs, the sum of conservative per-product error bounds can provide a deterministic upper bound on the absolute difference between the exact and approximate accumulated results, provided that:
- The bound is computed without overflow.
- The accumulator does not overflow.
- All quantization and saturation behavior matches the reference model.
- The accumulation window is reset and accounted for consistently.

A runtime controller can use this bound to select reduced precision when the configured budget permits and exact precision otherwise.

The mathematical guarantee is testable. Whether the architecture provides a worthwhile area, timing or energy advantage is an empirical question.

## 3. Candidate contributions

1. Operand-magnitude-dependent error-bound estimation for reduced-precision products.
2. Accumulation-window error-budget tracking with deterministic precision fallback.
3. A precision-scalable datapath supporting INT4, INT8 and exact INT16.
4. Formal properties for budget safety, transaction accounting and overflow handling.
5. Cross-platform evaluation using one RTL specification on FPGA and ASIC.
6. Workload-level analysis connecting arithmetic error to application accuracy.

These contributions must be compared with the closest prior work before being described as novel.

## 4. Research questions

- Does the error estimator conservatively bound actual product error for all supported input values, including signed endpoints and saturation?
- Can the accumulated error bound be enforced for all accepted operations?
- What is the estimator and controller overhead in area, timing and switching?
- Does structural precision gating reduce post-route dynamic power against an exact baseline?
- How does the design scale with accumulation length and parallel MAC lanes?
- How well does the arithmetic bound predict end-to-end inference error?

## 5. Required baselines

- B0: exact INT16 MAC.
- B1: fixed INT8 MAC.
- B2: fixed INT4 MAC.
- B3: selectable precision without an accumulation-level error budget.
- B4: proposed error-budgeted precision controller.

All comparisons must use the same operand traces, accumulation lengths, clock targets and measurement methodology.

## 6. Scope

### Included
- Signed fixed-point arithmetic.
- INT4, INT8 and INT16 modes.
- Runtime precision selection.
- Product-error estimation and accumulation-budget tracking.
- MAC accumulation and overflow detection.
- Parameterized accumulation length and lane count.
- Simulation, SVA and formal checks.
- FPGA implementation.
- ASIC synthesis, floorplanning, placement, CTS, routing, STA, DRC and LVS.
- Reproducible workload and PPA comparisons.

### Excluded from the first implementation
- Floating-point formats (FP8, BF16, FP16).
- A full neural-network accelerator / NoC.
- Analog in-memory compute.
- Fabricated silicon.
- Claims of measured silicon power without a fabricated and measured chip.

## 7. Novelty gate — mandatory

Existing literature already includes adaptive-precision MACs, energy-aware configurable MACs, overflow-driven dynamic precision scaling, and approximate MACs designed to control cumulative error. The candidate idea may overlap with these works.

Before committing to the final research claim:
1. Read the full text of the closest papers, especially their precision-selection algorithms and error guarantees.
2. Search IEEE Xplore, ACM Digital Library, Scopus/Web of Science, Google Scholar, arXiv, patents and public RTL repositories.
3. Build a feature-by-feature comparison matrix.
4. State the exact difference from the closest work in one falsifiable paragraph.
5. If equivalent error-budget enforcement already exists, revise the contribution before scaling RTL development.

## 8. Go / no-go criteria

Proceed to full RTL only after:
- The novelty gap is defensible.
- The mathematical bound is independently checked.
- A small reference model passes exhaustive boundary and randomized tests.
- The expected controller/datapath overhead is plausible.
- A measurable physical-design advantage can be tested.

Do not use “first,” “novel” or “state of the art” in a paper until supported by the completed review.
