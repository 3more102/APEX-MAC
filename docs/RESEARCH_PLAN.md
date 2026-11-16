# APEX-MAC Research Plan

## 1. Working title

**APEX-MAC: An Accumulation-Level Error-Budgeted Precision-Scalable MAC Architecture for Energy-Efficient Edge Inference**

The title is provisional and should be updated after the literature and novelty assessment.

## 2. Problem statement

Fixed-precision MAC units perform every operation at the same arithmetic precision, even when a workload can tolerate different numerical-error levels across operations or accumulation windows. Precision-scalable MACs address part of this problem, but the research must establish whether a controller that explicitly manages a cumulative error budget can provide a useful and formally testable design point.

The project will investigate the joint design of:
- A precision-scalable arithmetic datapath.
- A runtime precision-selection controller.
- A conservative error estimator.
- An accumulation-level error-budget tracker.
- A hardware evaluation methodology spanning FPGA and ASIC.

## 3. Research hypothesis

For bounded fixed-point workloads, a controller that selects the lowest supported precision whose conservative per-operation error bound fits within the remaining accumulation error budget can reduce switching activity and potentially energy, while guaranteeing that the accumulated arithmetic error remains within a configured bound, provided accumulator overflow and other non-arithmetic effects are excluded or separately handled.

This is a hypothesis to test, not a result.

## 4. Candidate contributions

1. **Accumulation-level error budgeting:** track a conservative sum of per-operation error bounds rather than selecting precision from a fixed mode or energy threshold alone.
2. **Magnitude-aware precision selection:** account for operand magnitudes and the selected quantization step when estimating the next operation's error.
3. **Precision-scalable datapath:** implement INT4, INT8 and exact INT16 modes, with structural operand isolation or partial-product gating whose hardware benefit is measured after synthesis and routing.
4. **Cross-platform evaluation:** use one RTL specification for FPGA and ASIC and report the differences in resource mapping, timing, power and energy.
5. **Workload-level validation:** evaluate numerical error and task accuracy on selected fixed-point inference workloads, not only isolated multiplier vectors.

The final contribution list must be narrowed to what is demonstrably new and supported by measured results.

## 5. Scope

### Included
- Signed fixed-point arithmetic.
- INT4, INT8 and INT16 operation modes.
- Runtime mode selection.
- Error-budget tracking and safety assertions.
- MAC accumulation and overflow monitoring.
- Parameterized vector length / accumulation window.
- FPGA implementation.
- ASIC synthesis, floorplanning, placement, CTS, routing, STA, DRC and LVS.
- Workload and PPA comparisons.

### Excluded from the first release
- Full floating-point formats (FP8, BF16, FP16).
- A complete neural-network accelerator / NoC.
- Analog in-memory compute.
- A fabricated silicon prototype.
- Claims of measured silicon power without silicon measurement.

## 6. Research questions

- Does the error-budget controller preserve its bound for all supported operand values and mode transitions?
- What is the area, timing and switching overhead of the estimator and controller?
- Does structural precision gating reduce post-route dynamic power relative to a fixed INT16 baseline?
- How does the design scale with accumulation length and channel count?
- How do FPGA and ASIC implementations differ?
- Does the arithmetic error bound predict application-level inference degradation adequately?

## 7. Required baselines

- B0: exact INT16 MAC.
- B1: fixed INT8 MAC.
- B2: fixed INT4 MAC.
- B3: conventional runtime precision selection without cumulative error tracking.
- B4: proposed error-budgeted precision selection.

All baselines must use the same operand traces, accumulation lengths, clock targets and evaluation methodology.

## 8. Go / no-go criteria

Do not commit to a publication novelty claim until:
- A systematic search of papers, theses, patents and open-source implementations is complete.
- The exact difference from the closest prior work is written in one falsifiable paragraph.
- The mathematical bound is independently checked.
- A small RTL prototype demonstrates that the controller does not invalidate the bound.
- Synthesis indicates that the proposed gating structure is physically meaningful.

If the novelty overlaps substantially with prior work, revise the contribution before scaling implementation.
