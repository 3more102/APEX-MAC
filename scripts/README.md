# Scripts

## Generic synthesis baseline

Run:

    bash scripts/run_generic_synth.sh

The script invokes Yosys on the single-lane RTL and writes the following to `reports/generic-synth/`:
- `metadata.txt`: timestamp, Git commit and Yosys version.
- `run.ys`: exact Yosys command script.
- `yosys.log`: full tool log.
- `stat.json`: generic mapped cell statistics.
- `netlist.json`: generic synthesized netlist.

The report is for reproducible RTL-variant comparison only. It is not ASIC standard-cell area, timing, power or signoff evidence.

## Operand-isolation activity comparison

Run:

    make activity-test

The runner builds baseline and operand-isolated RTL variants with Icarus, emits VCD traces, and uses analyze_operand_activity.py to count bit transitions at the multiplier input ports. It writes a CSV report and VCD traces under build/activity/.

This is an RTL input-activity proxy only. It is not a power or energy estimate.

## Planned scripts

This directory will later contain deterministic scripts for:
- Lint and RTL regression.
- Formal property execution.
- Operand trace and workload generation.
- Technology-mapped ASIC synthesis.
- OpenROAD physical-design stages.
- FPGA synthesis / place-and-route.
- PPA report extraction and paper figure generation.

Every run must record its input configuration, Git commit, tool version, random seed and output location. Never overwrite raw experiment results.
