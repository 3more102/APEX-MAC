# ASIC RTL-to-GDSII

Initial candidate flow: Yosys / ABC, OpenROAD-flow-scripts, OpenSTA and the SkyWater SKY130 HD platform.

Required stages:
1. RTL elaboration and lint.
2. Synthesis and technology mapping.
3. Floorplanning and pin placement.
4. Power-distribution planning.
5. Global placement and optimization.
6. Clock-tree synthesis.
7. Global and detailed routing.
8. Parasitic extraction.
9. Setup/hold static timing analysis.
10. DRC and LVS checks.
11. GDSII export and archived reports.

Record the PDK revision, process corner, voltage, temperature, clock constraints, libraries and tool versions. Do not describe a flow as signoff-complete unless the required physical checks have actually passed.
