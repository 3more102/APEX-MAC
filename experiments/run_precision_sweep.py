#!/usr/bin/env python3
"""Run deterministic synthetic APEX-MAC precision-policy experiments.

The script reports numerical error and precision-mode counts only. It does
not estimate or claim power, energy, area, or timing improvements.
"""
from __future__ import annotations

import argparse
import csv
import random
import sys
from pathlib import Path
from typing import Iterable

# Make the repository root importable when this file is executed by path.
REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from models.apex_mac_model import ApexMAC, error_bound_q30, quantize_q15


WORKLOADS = ("low_magnitude", "uniform", "sparse", "mixed")
FIELDS = (
    "workload",
    "policy",
    "samples",
    "error_budget_q30",
    "int4_ops",
    "int8_ops",
    "int16_ops",
    "actual_accum_error_q30",
    "error_bound_spent_q30",
    "accumulator_overflow",
)


def make_trace(name: str, samples: int, seed: int) -> list[tuple[int, int]]:
    rng = random.Random(seed)
    trace: list[tuple[int, int]] = []
    for _ in range(samples):
        if name == "low_magnitude":
            limits = (-8192, 8191)
            a, b = rng.randint(*limits), rng.randint(*limits)
        elif name == "uniform":
            a = rng.randint(-32768, 32767)
            b = rng.randint(-32768, 32767)
        elif name == "sparse":
            a = 0 if rng.random() < 0.75 else rng.randint(-32768, 32767)
            b = 0 if rng.random() < 0.75 else rng.randint(-32768, 32767)
        elif name == "mixed":
            if rng.random() < 0.5:
                a = rng.randint(-4096, 4095)
                b = rng.randint(-4096, 4095)
            else:
                a = rng.randint(-32768, 32767)
                b = rng.randint(-32768, 32767)
        else:
            raise ValueError(f"unknown workload: {name}")
        trace.append((a, b))
    return trace


def evaluate_fixed(
    workload: str, trace: Iterable[tuple[int, int]], precision: int
) -> dict[str, int | str | bool]:
    exact_sum = 0
    approximate_sum = 0
    bound_sum = 0
    count = 0
    for a, b in trace:
        qa = quantize_q15(a, precision)  # type: ignore[arg-type]
        qb = quantize_q15(b, precision)  # type: ignore[arg-type]
        approximate_sum += qa * qb
        exact_sum += a * b
        bound_sum += error_bound_q30(a, b, precision)  # type: ignore[arg-type]
        count += 1

    signed_min = -(1 << 47)
    signed_max = (1 << 47) - 1
    return {
        "workload": workload,
        "policy": f"fixed_int{precision}",
        "samples": count,
        "error_budget_q30": "",
        "int4_ops": count if precision == 4 else 0,
        "int8_ops": count if precision == 8 else 0,
        "int16_ops": count if precision == 16 else 0,
        "actual_accum_error_q30": abs(exact_sum - approximate_sum),
        "error_bound_spent_q30": bound_sum,
        "accumulator_overflow": not (signed_min <= approximate_sum <= signed_max),
    }


def evaluate_budgeted(
    workload: str, trace: Iterable[tuple[int, int]], budget_q30: int
) -> dict[str, int | str | bool]:
    mac = ApexMAC(budget_q30)
    counts = {4: 0, 8: 0, 16: 0}
    samples = 0
    for a, b in trace:
        result = mac.step(a, b)
        counts[result.precision] += 1
        samples += 1

    return {
        "workload": workload,
        "policy": "error_budgeted",
        "samples": samples,
        "error_budget_q30": budget_q30,
        "int4_ops": counts[4],
        "int8_ops": counts[8],
        "int16_ops": counts[16],
        "actual_accum_error_q30": mac.absolute_accumulation_error_q30,
        "error_bound_spent_q30": mac.error_spent_q30,
        "accumulator_overflow": mac.overflow,
    }


def parse_budgets(value: str) -> list[int]:
    try:
        budgets = [int(item.strip()) for item in value.split(",") if item.strip()]
    except ValueError as exc:
        raise argparse.ArgumentTypeError("budgets must be comma-separated integers") from exc
    if not budgets or any(item < 0 for item in budgets):
        raise argparse.ArgumentTypeError("provide one or more non-negative budgets")
    return budgets


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=20261116)
    parser.add_argument(
        "--budgets",
        type=parse_budgets,
        default=parse_budgets("0,100000000,500000000,2000000000"),
        help="comma-separated Q30 integer error budgets",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("experiments/results/precision_sweep.csv"),
    )
    args = parser.parse_args()
    if args.samples <= 0:
        parser.error("--samples must be positive")

    rows: list[dict[str, int | str | bool]] = []
    for index, workload in enumerate(WORKLOADS):
        trace = make_trace(workload, args.samples, args.seed + index)
        rows.extend(evaluate_fixed(workload, trace, precision) for precision in (4, 8, 16))
        rows.extend(evaluate_budgeted(workload, trace, budget) for budget in args.budgets)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} experiment rows to {args.output}")
    print("Metrics are numerical only; no power or PPA is inferred.")


if __name__ == "__main__":
    main()
