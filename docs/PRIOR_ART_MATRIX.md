# APEX-MAC Prior-Art Comparison Matrix

**Status:** preliminary comparison from publisher abstracts and metadata available on 16 November 2026. It is not a substitute for reading the full papers. "Not stated" means the abstract or accessible metadata did not establish the feature; it does not prove the paper lacks it.

| Prior work | Precision / datapath | Runtime selection trigger | Error treatment | ASIC / FPGA evidence | Consequence for APEX-MAC |
|---|---|---|---|---|---|
| Overflow-Driven Dynamic Precision Scaling Fixed-Point MAC (IEEE TVLSI, 2026) | Fixed-point, bit-sliced precision scaling | Hardware runtime monitor detects overflow / over-representation | Bounded rounding error; per-accumulation control | Artix-7 FPGA and SkyWater 130 nm ASIC | Very close: dynamic precision, per-accumulation monitoring, bounded error and both implementation targets are already demonstrated. Read full algorithm first. DOI: 10.1109/TVLSI.2026.3680254 |
| Adaptive Energy–Accuracy Trade-Offs in Configurable MAC Architectures (Electronics, 2026) | Configurable MAC with high-, medium- and low-precision modes | Available energy / energy budget | Accuracy trade-off evaluated at workload level | 90 nm CMOS synthesis and Ultra96-V2 FPGA | Runtime energy-aware precision and ASIC/FPGA comparison are not new by themselves. DOI: 10.3390/electronics15051129 |
| Adaptive-Precision SIMD Architecture for DNN Acceleration (Integration, 2026) | INT4 / INT8 / INT16, symmetric and asymmetric SIMD | Adaptive precision for DNN execution | DNN accuracy evaluated across models and datasets | ASIC and FPGA; 65 nm ASIC reported | Multi-precision SIMD MAC and resource reuse are established prior art. DOI: 10.1016/j.vlsi.2026.102666 |
| Reconfigurable Transprecision SIMD-MAC PE (VDAT, 2026) | BF16, FP8, FP4 and INT4 combinations; pipelined PE | Runtime transprecision mode | Approximate mantissa multiplication in BF16 mode | VC707 FPGA and 28 nm ASIC | A generic reconfigurable mixed-precision PE is not a sufficient differentiator. DOI: 10.1109/VDAT72243.2026.11704639 |
| Dynamic Precision Configurable MAC for Hardware Accelerators (Integration, 2025) | Precision-scalable MAC with bit bricks and fusion units | Configurable precision | Precision / PPA trade-offs | 45 nm CMOS synthesis | Optimized precision-configurable MAC structures already exist. DOI: 10.1016/j.vlsi.2025.102419 |
| Resource-Efficient Approximate MAC with Hierarchical Compressors and Balanced Error Control (2025) | Approximate compressor tree | Structural approximation | Counterbalances positive and negative errors during accumulation | Abstract-level implementation details require full-text review | Cumulative error behavior in MACs is already studied. DOI: 10.1109/ICACRS67045.2025.11324400 |
| Breaking the DSP Wall: Adaptive Error-Compensated MAC (Electronics, 2026) | DSP-free LUT-based tri-mode datapath | Software/hardware co-design with dynamic integer scaling | Statistical bias compensation | Zynq-7020 FPGA; activity-based power analysis reported | Error compensation and FPGA-only approximate MAC are not new by themselves. DOI: 10.3390/electronics15081586 |
| Runtime-Configurable Approximate MAC with Workload-Aware Mode Selection (SSRN, 2026) | Exact, Balanced and Aggressive modes | Workload indicators: tolerance, energy budget, accumulation length and sparsity | Approximation-aware mode control | Preprint; implementation claims require independent review | Workload-aware mode selection may overlap with an APEX controller. SSRN abstract ID 7488414; not treated as peer-reviewed evidence. |

## Candidate APEX-MAC position

| Feature | APEX-MAC candidate |
|---|---|
| Input format | Signed Q1.15 |
| Modes | INT4, INT8, exact INT16 |
| Decision input | Operand-dependent conservative product-error bound |
| State | Accumulated bound spent in the current reduction window |
| Policy | Choose lowest precision that fits remaining configured budget; otherwise exact |
| Correctness contract | Sum of per-product absolute-error bounds, conditional on no accumulator overflow |
| Verification target | RTL simulation plus formal proof of budget-safety properties |
| Physical targets | FPGA and ASIC RTL-to-GDSII |
| Evidence status | Reference-model / initial RTL prototype only; no PPA or board result |

## Research gap that still needs proof

The possible distinction is an explicit, externally configured **per-reduction absolute-error contract** enforced by operand-dependent product bounds and exact fallback, rather than:
- overflow / over-representation driven bit shifting;
- energy-availability-driven mode selection;
- fixed or workload-level precision modes; or
- compressor structures that statistically balance accumulated error.

This is only a candidate distinction. It is not yet established as novel. In particular, the 2026 overflow-driven MAC and 2025 balanced-error MAC are close enough that their full texts must be inspected for equivalent cumulative error accounting.

## Go / no-go decision

Do not scale the architecture or make a publication novelty claim until the following are answered:

1. Does any prior design maintain a programmable absolute error budget per dot product or accumulation window?
2. Does any prior design compute per-operation error bounds from both operand magnitudes and use them to select precision?
3. Does any prior design fall back to exact arithmetic when the remaining budget cannot accommodate a reduced-precision operation?
4. Are these properties formally proven, empirically checked, or only statistically characterized?
5. What additional measurable contribution remains if the policy itself is already known?

If the full-text review finds equivalent mechanisms, preserve the APEX-MAC repository and redirect the paper contribution toward a genuinely distinct datapath, scheduler, formal guarantee or workload-specific co-design.
