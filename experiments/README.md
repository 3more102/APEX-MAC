# Experiments

Store raw inputs, configuration files, tool logs, machine-readable reports and derived plots in separate, clearly named run directories.

Each run should include:
- Run identifier and date.
- Git commit SHA.
- RTL/model version.
- Tool versions and exact commands.
- Random seed and workload.
- Clock, PDK and corner settings where applicable.
- Raw results and analysis scripts.

Never overwrite raw experiment results. Summaries and plots must be regenerable from archived data.
