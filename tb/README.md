# RTL Testbench

The SystemVerilog testbench will compare the DUT against the independent Python reference vectors and verify protocol behavior.

Planned test groups:
- Directed arithmetic and boundary cases.
- Precision-selection and budget-boundary cases.
- Randomized operand and budget sequences.
- Valid/ready back-pressure.
- Reset and accumulation-window transitions.
- Overflow and recovery behavior.
