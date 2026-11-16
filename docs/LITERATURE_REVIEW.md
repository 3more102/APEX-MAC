# APEX-MAC Initial Literature Landscape

**Status:** preliminary search notes, not a completed systematic review. The purpose is to identify close prior work and prevent unsupported novelty claims.

## 1. Closest work identified

### Adaptive-precision SIMD architecture for high-throughput and resource-efficient DNN acceleration
- Authors: Vasundhara Trivedi, Harman Singh Bagga, Gopal Raut and Santosh Kumar Vishvakarma.
- Journal: *Integration*, 2026, article 102666.
- DOI: https://doi.org/10.1016/j.vlsi.2026.102666
- Relevance: adaptive precision in MAC processing elements, 4/8/16-bit modes, asymmetric operations, resource reuse, ASIC and FPGA evaluation.
- Implication: APEX-MAC cannot claim novelty merely for supporting multiple precision modes or cross-platform implementation.

### XtraMAC: An Efficient MAC Architecture for Mixed-Precision LLM Inference on FPGA
- Authors: Feng Yu et al.
- Venue: ISCA 2026.
- DOI: https://doi.org/10.1109/ISCA66397.2026.00177
- Relevance: runtime-adaptive mixed data types, shared arithmetic resources and FPGA evaluation.
- Implication: a generic runtime-configurable MAC is not a sufficient research gap.

### Adaptive Energy—Accuracy Trade-Offs in Configurable MAC Architectures for AI Acceleration
- Authors: Turki Alnuayri and Ibrahim Haddadi.
- Journal: *Electronics*, 2026, 15(5), 1129.
- DOI: https://doi.org/10.3390/electronics15051129
- Relevance: runtime configurable MAC, energy-aware precision adaptation, bit-level logic compression, ASIC synthesis and FPGA deployment.
- Implication: energy-driven precision switching and ASIC/FPGA evaluation are already reported.

### Breaking the DSP Wall: A Software–Hardware Co-Designed, Adaptive Error-Compensated MAC Architecture for Efficient Edge AI
- Authors: Changyan Liu and Juntai Heiyan.
- Journal: *Electronics*, 2026, 15(8), 1586.
- DOI: https://doi.org/10.3390/electronics15081586
- Relevance: adaptive error-compensated MAC, DSP-free FPGA datapath and workload-level validation.
- Implication: error compensation alone is not a sufficient novelty claim.

## 2. Candidate differentiation to investigate

The candidate APEX-MAC angle is **accumulation-level error-budget enforcement**:
- Derive a conservative per-operation error bound from operand magnitudes and quantization step.
- Track the sum of accepted error bounds across an accumulation window.
- Select the lowest precision whose bound fits the remaining budget.
- Fall back to exact INT16 when no reduced mode fits.
- Formally verify that the configured budget is not exceeded, under explicit assumptions.

This is a candidate differentiation, not a verified literature gap. Search for prior work using terms such as:
- cumulative error budget MAC,
- error-budgeted approximate computing,
- precision selection with accumulated error bounds,
- runtime error-bound enforcement in fixed-point accelerators,
- per-output error budgeting for neural-network arithmetic,
- formally verified approximate MAC.

## 3. Required systematic review

Before publication, search IEEE Xplore, ACM Digital Library, Scopus/Web of Science, Google Scholar, arXiv, patents and open-source repositories. Record:
- Search query and date.
- Publication title, authors, venue and DOI.
- Arithmetic formats and precision modes.
- Runtime selection policy.
- Error estimator / error guarantee.
- Datapath structure.
- FPGA / ASIC target and process node.
- PPA and workload metrics.
- Source code availability.
- Exact overlap and difference from APEX-MAC.

## 4. Novelty decision

Do not write “first,” “novel,” or “state of the art” in the manuscript until the systematic review supports that statement. If a prior work already implements cumulative error-budget enforcement with equivalent guarantees, the project must be redirected to a distinct, measurable contribution.
