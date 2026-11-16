# ASIC RTL-to-GDSII

## Current baseline

The repository includes a generic Yosys synthesis script:

    bash scripts/run_generic_synth.sh

It produces:
- Yosys version and run metadata.
- Generic mapped cell statistics.
- A JSON netlist.
- Full synthesis log.

The generic cell count is useful for comparing RTL variants under the same tool version and script. It is **not** a foundry standard-cell area estimate, timing closure result, power result, or ASIC signoff report.

## Planned technology-mapped flow

Initial candidate: SkyWater SKY130 HD with OpenROAD-flow-scripts.

Required stages:
1. RTL elaboration, lint and synthesis checks.
2. Technology mapping against the selected PDK libraries.
3. Floorplanning and pin placement.
4. Power-distribution planning.
5. Global placement and optimization.
6. Clock-tree synthesis.
7. Global and detailed routing.
8. Parasitic extraction.
9. Setup/hold static timing analysis.
10. DRC and LVS checks.
11. GDSII export and archived reports.

Record the exact PDK revision, process corner, voltage, temperature, clock constraints, libraries, tool versions and commands. Do not describe the flow as signoff-complete unless required physical checks have actually passed.

## Comparison discipline

Compare exact INT16 and precision-scalable variants with:
- Identical timing constraints.
- Identical PDK and corner.
- Identical synthesis / physical-design tool versions.
- Identical utilization targets and floorplan assumptions.
- Identical activity traces for power estimation.

Report synthesis, placement, post-CTS and post-route results separately. Do not label generic Yosys cell counts as ASIC PPA.
