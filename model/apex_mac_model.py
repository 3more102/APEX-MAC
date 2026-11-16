"""Integer reference model for the initial APEX-MAC arithmetic contract.

Operands are signed Q1.15 raw integers. Products and the accumulator use
Q2.30 scaling. This model is a specification aid, not RTL or PPA evidence.
"""
from dataclasses import dataclass

SUPPORTED_PRECISIONS = (4, 8, 16)
INPUT_MIN = -(1 << 15)
INPUT_MAX = (1 << 15) - 1


def _check_input(raw: int) -> None:
    if not INPUT_MIN <= raw <= INPUT_MAX:
        raise ValueError(f"Q1.15 raw input out of range: {raw}")


def round_shift_ties_even(value: int, shift: int) -> int:
    """Round signed integer / 2**shift to nearest, ties to even."""
    if shift < 0:
        return value << (-shift)
    if shift == 0:
        return value
    sign = -1 if value < 0 else 1
    quotient, remainder = divmod(abs(value), 1 << shift)
    halfway = 1 << (shift - 1)
    if remainder > halfway or (remainder == halfway and (quotient & 1)):
        quotient += 1
    return sign * quotient


def quantize_q1_15(raw: int, precision: int) -> int:
    """Quantize Q1.15 raw input to signed Q1.(precision-1), return Q1.15 raw."""
    _check_input(raw)
    if precision not in SUPPORTED_PRECISIONS:
        raise ValueError(f"Unsupported precision: {precision}")
    if precision == 16:
        return raw

    shift = 16 - precision
    code = round_shift_ties_even(raw, shift)
    code_min = -(1 << (precision - 1))
    code_max = (1 << (precision - 1)) - 1
    code = min(max(code, code_min), code_max)
    return code << shift


def product_error_bound_q30(a_raw: int, b_raw: int, precision: int) -> int:
    """Conservative absolute product-error bound in Q30 integer units."""
    _check_input(a_raw)
    _check_input(b_raw)
    if precision not in SUPPORTED_PRECISIONS:
        raise ValueError(f"Unsupported precision: {precision}")
    if precision == 16:
        return 0
    shift = 16 - precision
    return ((abs(a_raw) + abs(b_raw)) << shift) + (1 << (32 - 2 * precision))


def quantized_product_q30(a_raw: int, b_raw: int, precision: int) -> int:
    """Return quantized product as a signed Q30 raw integer."""
    qa = quantize_q1_15(a_raw, precision)
    qb = quantize_q1_15(b_raw, precision)
    return qa * qb


def select_precision(a_raw: int, b_raw: int, remaining_budget_q30: int):
    """Choose the lowest precision that fits; return (precision, bound)."""
    _check_input(a_raw)
    _check_input(b_raw)
    if remaining_budget_q30 < 0:
        raise ValueError("Remaining error budget must be non-negative")
    for precision in (4, 8):
        bound = product_error_bound_q30(a_raw, b_raw, precision)
        if bound <= remaining_budget_q30:
            return precision, bound
    return 16, 0


@dataclass
class ErrorBudgetMAC:
    """Single-lane accumulation-window model with explicit overflow detection."""

    budget_q30: int
    accumulator_width: int = 48
    error_spent_q30: int = 0
    accumulator_q30: int = 0
    operation_count: int = 0

    def __post_init__(self):
        if self.budget_q30 < 0:
            raise ValueError("Error budget must be non-negative")
        if self.accumulator_width < 2:
            raise ValueError("Accumulator width must be at least 2")

    @property
    def accumulator_min(self) -> int:
        return -(1 << (self.accumulator_width - 1))

    @property
    def accumulator_max(self) -> int:
        return (1 << (self.accumulator_width - 1)) - 1

    @property
    def remaining_budget_q30(self) -> int:
        return self.budget_q30 - self.error_spent_q30

    def step(self, a_raw: int, b_raw: int) -> int:
        """Accept one MAC operation; return selected precision.

        Raises OverflowError before state update if the accumulator would
        exceed its configured signed width.
        """
        precision, bound = select_precision(
            a_raw, b_raw, self.remaining_budget_q30
        )
        product = quantized_product_q30(a_raw, b_raw, precision)
        next_accumulator = self.accumulator_q30 + product
        if not self.accumulator_min <= next_accumulator <= self.accumulator_max:
            raise OverflowError("Accumulator overflow")
        next_error_spent = self.error_spent_q30 + bound
        if next_error_spent > self.budget_q30:
            raise AssertionError("Internal error-budget contract violated")

        self.accumulator_q30 = next_accumulator
        self.error_spent_q30 = next_error_spent
        self.operation_count += 1
        return precision

    def reset_window(self) -> None:
        """Atomically reset the accumulator and error budget usage."""
        self.error_spent_q30 = 0
        self.accumulator_q30 = 0
        self.operation_count = 0
