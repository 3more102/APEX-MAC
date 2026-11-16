import random
import unittest

from model.apex_mac_model import (
    ErrorBudgetMAC,
    INPUT_MAX,
    INPUT_MIN,
    product_error_bound_q30,
    quantize_q1_15,
    quantized_product_q30,
    select_precision,
)


class TestQuantization(unittest.TestCase):
    def test_exact_mode_is_identity(self):
        for value in (INPUT_MIN, -1, 0, 1, INPUT_MAX):
            self.assertEqual(quantize_q1_15(value, 16), value)

    def test_quantized_operand_error_within_one_lsb(self):
        rng = random.Random(20261116)
        for precision in (4, 8):
            max_error_raw = 1 << (16 - precision)
            for _ in range(5000):
                value = rng.randint(INPUT_MIN, INPUT_MAX)
                quantized = quantize_q1_15(value, precision)
                self.assertLessEqual(abs(value - quantized), max_error_raw)

    def test_signed_endpoints(self):
        self.assertEqual(quantize_q1_15(INPUT_MIN, 4), INPUT_MIN)
        self.assertEqual(quantize_q1_15(INPUT_MAX, 4), 7 << 12)
        self.assertEqual(quantize_q1_15(INPUT_MAX, 8), 127 << 8)

    def test_invalid_precision_rejected(self):
        with self.assertRaises(ValueError):
            quantize_q1_15(0, 12)


class TestErrorBound(unittest.TestCase):
    def test_exact_mode_has_zero_bound(self):
        self.assertEqual(product_error_bound_q30(1234, -5678, 16), 0)

    def test_bound_dominates_random_product_error(self):
        rng = random.Random(20261117)
        for precision in (4, 8):
            for _ in range(10000):
                a = rng.randint(INPUT_MIN, INPUT_MAX)
                b = rng.randint(INPUT_MIN, INPUT_MAX)
                exact = a * b
                approximate = quantized_product_q30(a, b, precision)
                bound = product_error_bound_q30(a, b, precision)
                self.assertLessEqual(abs(exact - approximate), bound)

    def test_bound_is_tighter_for_higher_precision(self):
        a, b = 12000, -9000
        self.assertLess(
            product_error_bound_q30(a, b, 8),
            product_error_bound_q30(a, b, 4),
        )


class TestPrecisionSelection(unittest.TestCase):
    def test_int4_exact_fit_is_accepted(self):
        a, b = 12000, -9000
        bound4 = product_error_bound_q30(a, b, 4)
        self.assertEqual(select_precision(a, b, bound4), (4, bound4))

    def test_int8_selected_when_int4_does_not_fit(self):
        a, b = 12000, -9000
        bound8 = product_error_bound_q30(a, b, 8)
        self.assertEqual(select_precision(a, b, bound8), (8, bound8))

    def test_exact_selected_when_no_reduced_mode_fits(self):
        self.assertEqual(select_precision(12000, -9000, 0), (16, 0))

    def test_negative_budget_rejected(self):
        with self.assertRaises(ValueError):
            select_precision(1, 1, -1)


class TestErrorBudgetMAC(unittest.TestCase):
    def test_budget_is_never_exceeded(self):
        a, b = 12000, -9000
        budget = product_error_bound_q30(a, b, 4)
        mac = ErrorBudgetMAC(budget_q30=budget)
        first_mode = mac.step(a, b)
        second_mode = mac.step(a, b)
        self.assertEqual(first_mode, 4)
        self.assertEqual(second_mode, 16)
        self.assertLessEqual(mac.error_spent_q30, budget)

    def test_accumulated_error_is_bounded(self):
        rng = random.Random(20261118)
        pairs = [
            (rng.randint(INPUT_MIN, INPUT_MAX), rng.randint(INPUT_MIN, INPUT_MAX))
            for _ in range(100)
        ]
        budget = 1 << 42
        mac = ErrorBudgetMAC(budget_q30=budget)
        exact_sum = 0
        for a, b in pairs:
            exact_sum += a * b
            mac.step(a, b)
        self.assertLessEqual(
            abs(exact_sum - mac.accumulator_q30),
            mac.error_spent_q30,
        )

    def test_reset_starts_new_window(self):
        mac = ErrorBudgetMAC(budget_q30=1 << 40)
        mac.step(12000, -9000)
        mac.reset_window()
        self.assertEqual(mac.error_spent_q30, 0)
        self.assertEqual(mac.accumulator_q30, 0)
        self.assertEqual(mac.operation_count, 0)

    def test_overflow_raises_before_state_update(self):
        mac = ErrorBudgetMAC(budget_q30=0, accumulator_width=8)
        mac.accumulator_q30 = 127
        with self.assertRaises(OverflowError):
            mac.step(1, 1)
        self.assertEqual(mac.accumulator_q30, 127)


if __name__ == "__main__":
    unittest.main()
