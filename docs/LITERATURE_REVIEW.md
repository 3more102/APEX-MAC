# APEX-MAC Initial Literature Review

**Status:** Preliminary landscape only; not a systematic review. This document records known close work to prevent unsupported novelty claims.

## 1. Closest identified publications

### Overflow-Driven Dynamic Precision Scaling Fixed-Point Multiply-Accumulator Unit
- Venue: IEEE Transactions on Very Large Scale Integration (VLSI) Systems, vol. 34, issue 6, June 2026, pp. 1814–1822.
- DOI: https://doi.org/10.1109/TVLSI.2026.3680254
- Relevance: hardware runtime monitoring, per-accumulation dynamic precision, bounded rounding error, FPGA prototype and SkyWater 130 nm ASIC implementation.
- Implication: APEX-MAC cannot claim novelty for hardware-only dynamic precision, per-accumulation monitoring, or FPGA/ASIC implementation alone. Full-text comparison is mandatory.

### Adaptive Energy—Accuracy Trade-Offs in Configurable MAC Architectures for AI Acceleration
- Authors: Turki Alnuayri and Ibrahim Haddadi.
- Venue: Electronics, 2026, 15(5), 1129.
- DOI: https://doi.org/10.3390/electronics15051129
- Relevance: runtime-configurable MAC, energy-aware mode selection, ASIC synthesis and FPGA deployment.
- Implication: energy-driven precision switching and cross-platform evaluation are already reported.

### Adaptive-Precision SIMD Architecture for High-Throughput and Resource-Efficient DNN Acceleration
- Authors: Vasundhara Trivedi, Harman Singh Bagga, Gopal Raut and Santosh Kumar Vishvakarma.
- Venue: Integration, 2026, article 102666.
- DOI: https://doi.org/10.1016/j.vlsi.2026.102666
- Relevance: 4/8/16-bit adaptive precision, SIMD processing elements, resource reuse, ASIC and FPGA evaluation.
- Implication: multi-precision support and adaptive SIMD MAC design are not sufficient novelty.

### A Reconfigurable Transprecision SIMD-MAC PE for Mixed-Precision Edge-AI Applications
- Venue: 2026 IEEE International Symposium on VLSI Design and Test (VDAT).
- DOI: https://doi.org/10.1109/VDAT72243.2026.11704639
- Relevance: mixed precision, reusable multiplier resources, FPGA and 28 nm ASIC evaluation.
- Implication: a generic transprecision MAC with cross-platform PPA is already an active research direction.

### Dynamic Precision Configurable Multiply and Accumulate Architecture for Hardware Accelerators
- Venue: Integration, 2025.
- DOI: https://doi.org/10.1016/j.vlsi.2025.102419
- Relevance: precision-scalable MAC, optimized bit bricks and fusion units, CMOS synthesis.
- Implication: precision-configurable multiplier/accumulator architecture is established prior art.

### A Resource Efficient Approximate MAC using Hierarchical Compressors with Balanced Error Control
- DOI: https://doi.org/10.1109/ICACRS67045.2025.11324400
- Relevance: approximate compressors designed to counterbalance errors during accumulation.
- Implication: cumulative-error behavior in MACs must be examined, not assumed to be unexplored.

### Breaking the DSP Wall: A Software–Hardware Co-Designed, Adaptive Error-Compensated MAC Architecture for Efficient Edge AI
- Venue: Electronics, 2026, 15(8), 1586.
- DOI: https://doi.org/10.3390/electronics15081586
- Relevance: adaptive error-compensated MAC, FPGA implementation and workload-level evaluation.
- Implication: error compensation alone is not a sufficient contribution.

### Runtime-Configurable Approximate MAC Architecture with Workload-Aware Mode Selection for Energy-Efficient ASIC Accelerators
- Venue: SSRN preprint, posted 19 September 2026.
- URL: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=7488414
- Relevance: workload-aware runtime mode selection using error tolerance, energy budget, accumulation length and sparsity indicators.
- Status: preprint; peer-review status must be checked before citing as a peer-reviewed publication.

## 2. Candidate differentiation to investigate

The candidate APEX-MAC mechanism is a **configured per-accumulation numerical-error budget** with operand-dependent conservative product bounds, deterministic precision fallback and formal safety properties.

This may still overlap with prior work, especially the 2026 overflow-driven MAC and 2025 balanced-error MAC. The full texts and detailed algorithms must be compared before proceeding.

## 3. Required systematic review

Search IEEE Xplore, ACM Digital Library, Scopus/Web of Science, Google Scholar, arXiv, patent databases and public RTL repositories. Record:
- Search query and search date.
- Paper title, authors, venue and DOI.
- Supported formats and precision modes.
- Runtime selection policy.
- Error estimator and guarantee.
- Accumulation behavior.
- Hardware structure.
- FPGA / ASIC target, process node and tools.
- PPA and workload metrics.
- RTL or artifact availability.
- Exact overlap and difference from APEX-MAC.

Suggested search terms:
- accumulation error budget fixed-point MAC
- runtime error-bound enforcement approximate computing
- adaptive precision MAC cumulative error
- formally verified approximate arithmetic
- operand-dependent precision selection dot product
- error-bounded mixed-precision accelerator

## 4. Novelty decision

Do not write “first,” “novel” or “state of the art” in the paper until the systematic review supports that statement. If equivalent error-budget enforcement already exists, revise the project contribution before expanding RTL.
