#!/usr/bin/env python3
"""Count VCD bit transitions at APEX-MAC multiplier input ports.

This is a switching-activity proxy only. It is not a power or energy estimate.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path


TARGETS = ("multiplier_operand_a", "multiplier_operand_b")


def count_vcd_toggles(path: Path) -> dict[str, dict[str, int]]:
    identifiers: dict[str, tuple[str, int]] = {}
    previous: dict[str, str] = {}
    counts = {
        name: {"bit_toggles": 0, "vector_transitions": 0}
        for name in TARGETS
    }
    in_definitions = True

    with path.open("r", encoding="utf-8", errors="replace") as stream:
        for raw_line in stream:
            line = raw_line.strip()
            if not line:
                continue

            if in_definitions:
                if line.startswith("$var"):
                    fields = line.split()
                    if len(fields) >= 6:
                        width = int(fields[2])
                        identifier = fields[3]
                        reference = fields[4]
                        if reference in TARGETS:
                            identifiers[identifier] = (reference, width)
                elif line.startswith("$enddefinitions"):
                    in_definitions = False
                continue

            if line[0] in "bB":
                fields = line[1:].split()
                if len(fields) != 2:
                    continue
                value, identifier = fields
            elif line[0] in "01xXzZ":
                value, identifier = line[0], line[1:]
            else:
                continue

            if identifier not in identifiers:
                continue

            signal_name, width = identifiers[identifier]
            value = value.lower().zfill(width)
            if len(value) > width:
                value = value[-width:]
            if any(bit not in "01" for bit in value):
                previous.pop(identifier, None)
                continue

            old_value = previous.get(identifier)
            if old_value is not None and old_value != value:
                counts[signal_name]["bit_toggles"] += (
                    int(old_value, 2) ^ int(value, 2)
                ).bit_count()
                counts[signal_name]["vector_transitions"] += 1
            previous[identifier] = value

    found = {name for name, _width in identifiers.values()}
    missing = set(TARGETS) - found
    if missing:
        raise RuntimeError(
            f"VCD did not contain expected multiplier signals: {sorted(missing)}"
        )
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--isolated", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    results = {
        "baseline": count_vcd_toggles(args.baseline),
        "operand_isolated": count_vcd_toggles(args.isolated),
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(("variant", "signal", "bit_toggles", "vector_transitions"))
        for variant, signals in results.items():
            for signal, metrics in signals.items():
                writer.writerow((
                    variant,
                    signal,
                    metrics["bit_toggles"],
                    metrics["vector_transitions"],
                ))

    baseline_total = sum(
        item["bit_toggles"] for item in results["baseline"].values()
    )
    isolated_total = sum(
        item["bit_toggles"] for item in results["operand_isolated"].values()
    )
    reduction = (
        100.0 * (baseline_total - isolated_total) / baseline_total
        if baseline_total else 0.0
    )

    print(f"Baseline multiplier-input bit toggles: {baseline_total}")
    print(f"Isolated multiplier-input bit toggles: {isolated_total}")
    print(f"Observed input-toggle reduction: {reduction:.2f}%")
    print("This is an RTL input-activity proxy, not measured power or energy.")
    print(f"CSV report: {args.output}")


if __name__ == "__main__":
    main()
