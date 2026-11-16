# APEX-MAC Experiments

## Precision-policy sweep

Run a deterministic synthetic workload sweep from the repository root:

\`\`\`bash
python experiments/run_precision_sweep.py --samples 10000
\`\`\`

Optional arguments:

- \`--seed 20261116\`: deterministic random seed.
- \`--budgets 0,100000000,500000000,2000000000\`: comma-separated Q30 integer error budgets.
- \`--output experiments/results/precision_sweep.csv\`: output CSV path.

The script evaluates four synthetic operand distributions:
- \`low_magnitude\`
- \`uniform\`
- \`sparse\`
- \`mixed\`

For each workload it compares fixed INT4, fixed INT8, exact INT16 and the error-budgeted policy. The CSV records mode counts, accumulated numerical error, conservative error bound spent and accumulator overflow.

## Interpretation limits

These synthetic experiments are for functional policy exploration only. They are not representative of a trained model unless real operand traces are supplied. They do not measure or estimate energy, power, area, timing, throughput, FPGA DSP utilization or ASIC PPA.

A publication-quality evaluation must add reproducible traces from named workloads, document preprocessing and fixed-point scaling, measure task-level accuracy, and use activity-aware power analysis and physical-design reports.
