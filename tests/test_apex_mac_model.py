import random
import unittest

from models.apex_mac_model import (
    ApexMAC,
    error_bound_q30,
    quantize_q15,
    select_precision,
)


class TestQuantizer(unittest.TestCase):
    def test_int16_is_exact(self):
        for value in (-32768, -1, 0, 1, 32767):
            self.assertEqual(quantize_q15(value, 16), value)

    def test_signed_endpoints_and_saturation(self):
        self.assertEqual(quantize_q15(-32768, 4), -32768)
        self.assertEqual(quantize_q15(32767, 4), 7 << 12)
        self.assertEqual(quantize_q15(-32768, 8), -32768)
        self.assertEqual(quantize_q15(32767, 8), 127 << 8)

    def test_round_to_nearest_ties_to_even(self):
        self.assertEqual(quantize_q15(1 << 11, 4), 0)
        self.assertEqual(quantize_q15(3 << 11, 4), 2 << 12)
        self.assertEqual(quantize_q15(-(1 << 11), 4), 0)
        self.assertEqual(quantize_q15(-(3 << 11), 4), -(2 << 12))


class TestErrorBound(unittest.TestCase):
    def test_exact_mode_has_zero_bound(self):
        self.assertEqual(error_bound_q30(32767, -32768, 16), 0)

    def test_randomized_bound_covers_actual_product_error(self):
        rng = random.Random(20261116)
        edge_values = (-32768, -32767, -16385, -1, 0, 1, 16383, 32766, 32767)
        for precision in (4, 8):
            pairs = [(a, b) for a in edge_values for b in edge_values]
            pairs.extend(
                (rng.randint(-32768, 32767), rng.randint(-32768, 32767))
                for _ in range(20000)
            )
            for a, b in pairs:
                qa = quantize_q15(a, precision)
                qb = quantize_q15(b, precision)
                actual_error = abs((a * b) - (qa * qb))
                self.assertLessEqual(actual_error, error_bound_q30(a, b, precision))


class TestPrecisionPolicy(unittest.TestCase):
    def test_int4_selected_at_exact_budget_boundary(self):
        a, b = 1000, -2000
        bound4 = error_bound_q30(a, b, 4)
        self.assertEqual(select_precision(a, b, bound4, 0), (4, bound4))

    def test_int8_selected_when_int4_does_not_fit(self):
        a, b = 1000, 1000
        bound4 = error_bound_q30(a, b, 4)
        bound8 = error_bound_q30(a, b, 8)
        self.assertGreater(bound4, bound8)
        self.assertEqual(select_precision(a, b, bound8, 0), (8, bound8))

    def test_exact_selected_when_no_reduced_mode_fits(self):
        self.assertEqual(select_precision(32767, -32768, 0, 0), (16, 0))

    def test_spent_budget_is_subtracted_before_selection(self):
        a, b = 1000, 1000
        bound4 = error_bound_q30(a, b, 4)
        bound8 = error_bound_q30(a, b, 8)
        self.assertEqual(select_precision(a, b, bound4 + bound8, bound4), (8, bound8))


class TestMACState(unittest.TestCase):
    def test_accumulated_error_stays_within_budget(self):
        a_values = (1000, -5000, 12000, 32767, -32768, 77, -99)
        b_values = (-2000, 6000, 3000, -32768, 32767, 1234, 987)
        budget = 200_000_000
        mac = ApexMAC(budget)
        for a, b in zip(a_values, b_values):
            result = mac.step(a, b)
            self.assertLessEqual(result.error_spent_q30, budget)
        self.assertFalse(mac.overflow)
        self.assertLessEqual(mac.absolute_accumulation_error_q30, mac.error_spent_q30)

    def test_exact_mode_accumulates_without_spending_error_budget(self):
        mac = ApexMAC(0)
        result = mac.step(32767, -12345)
        self.assertEqual(result.precision, 16)
        self.assertEqual(result.error_bound_q30, 0)
        self.assertEqual(result.product_q30, 32767 * -12345)
        self.assertEqual(result.accumulator_q30, 32767 * -12345)
        self.assertEqual(result.error_spent_q30, 0)

    def test_overflow_is_sticky_and_accumulator_holds(self):
        mac = ApexMAC(0)
        mac.accumulator_q30 = (1 << 47) - 1
        before = mac.accumulator_q30
        result = mac.step(32767, 32767)
        self.assertTrue(result.overflow)
        self.assertEqual(result.accumulator_q30, before)
        result2 = mac.step(1, 1)
        self.assertTrue(result2.overflow)
        self.assertEqual(result2.accumulator_q30, before)

    def test_frame_reset_clears_accumulator_and_error_state(self):
        mac = ApexMAC(100_000_000)
        mac.step(1000, 1000)
        self.assertNotEqual(mac.error_spent_q30, 0)
        mac.reset_frame()
        self.assertEqual(mac.accumulator_q30, 0)
        self.assertEqual(mac.error_spent_q30, 0)
        self.assertEqual(mac.exact_accumulator_q30, 0)
        self.assertFalse(mac.overflow)


if __name__ == "__main__":
    unittest.main()
