import csv
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


class TestPrecisionSweepScript(unittest.TestCase):
    def test_small_sweep_writes_expected_rows(self):
        repo_root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "sweep.csv"
            subprocess.run(
                [
                    sys.executable,
                    str(repo_root / "experiments" / "run_precision_sweep.py"),
                    "--samples",
                    "32",
                    "--budgets",
                    "0,100000000",
                    "--output",
                    str(output),
                ],
                cwd=repo_root,
                check=True,
                capture_output=True,
                text=True,
            )
            with output.open(newline="", encoding="utf-8") as stream:
                rows = list(csv.DictReader(stream))

        # 4 workloads * (3 fixed modes + 2 error budgets)
        self.assertEqual(len(rows), 20)
        self.assertEqual(rows[0]["policy"], "fixed_int4")
        self.assertEqual(rows[2]["policy"], "fixed_int16")
        self.assertEqual(rows[3]["policy"], "error_budgeted")
        for row in rows:
            self.assertLessEqual(
                int(row["actual_accum_error_q30"]),
                int(row["error_bound_spent_q30"]),
            )


if __name__ == "__main__":
    unittest.main()
