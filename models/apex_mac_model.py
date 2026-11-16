"""Bit-accurate integer reference model for APEX-MAC.

All operands are signed Q1.15 integers. Products and error bounds are
represented as signed/unsigned integer counts in Q2.30 units respectively.
The model uses only the Python standard library.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

Precision = Literal[4, 8, 16]
INPUT_MIN = -(1 << 15)
INPUT_MAX = (1 << 15) - 1


def _check_operand(value: int) -> None:
    if not INPUT_MIN <= value <= INPUT_MAX:
        raise ValueError(f"Q1.15 operand out of range: {value}")


def round_shift_ties_even(value: int, shift: int) -> int:
    """Round a signed integer divided by 2**shift to nearest, ties to even."""
    if shift < 1:
        raise ValueError("shift must be >= 1")
    sign = -1 if value < 0 else 1
    magnitude = abs(value)
    quotient, remainder = divmod(magnitude, 1 << shift)
    half = 1 << (shift - 1)
    if remainder > half or (remainder == half and (quotient & 1)):
        quotient += 1
    return sign * quotient


def quantize_q15(value: int, precision: Precision) -> int:
    """Quantize Q1.15 raw integer to signed Q1.(precision-1), then re-align Q1.15."""
    _check_operand(value)
    if precision == 16:
        return value
    if precision not in (4, 8):
        raise ValueError(f"unsupported precision: {precision}")

    shift = 16 - precision
    quantized = round_shift_ties_even(value, shift)
    minimum = -(1 << (precision - 1))
    maximum = (1 << (precision - 1)) - 1
    quantized = min(max(quantized, minimum), maximum)
    return quantized << shift


def error_bound_q30(a: int, b: int, precision: Precision) -> int:
    """Conservative bound on |a*b - Qp(a)*Qp(b)| in Q2.30 integer units.

    The bound uses |delta_a|, |delta_b| <= 2**(-(precision-1)).
    Saturation endpoints are included by this conservative bound.
    """
    _check_operand(a)
    _check_operand(b)
    if precision == 16:
        return 0
    if precision not in (4, 8):
        raise ValueError(f"unsupported precision: {precision}")
    return ((abs(a) + abs(b)) << (16 - precision)) + (1 << (32 - 2 * precision))


def select_precision(
    a: int, b: int, error_budget_q30: int, error_spent_q30: int = 0
) -> tuple[Precision, int]:
    """Choose the lowest precision whose conservative bound fits the remaining budget."""
    _check_operand(a)
    _check_operand(b)
    if error_budget_q30 < 0 or error_spent_q30 < 0:
        raise ValueError("error budget and spent error must be non-negative")

    if error_spent_q30 > error_budget_q30:
        return 16, 0

    remaining = error_budget_q30 - error_spent_q30
    bound4 = error_bound_q30(a, b, 4)
    if bound4 <= remaining:
        return 4, bound4

    bound8 = error_bound_q30(a, b, 8)
    if bound8 <= remaining:
        return 8, bound8

    return 16, 0


@dataclass(frozen=True)
class MACStep:
    precision: Precision
    quantized_a_q15: int
    quantized_b_q15: int
    product_q30: int
    error_bound_q30: int
    accumulator_q30: int
    error_spent_q30: int
    overflow: bool


class ApexMAC:
    """Single-lane behavioral MAC with a fixed per-frame error budget.

    On signed accumulator overflow the accumulator holds its previous value
    and a sticky overflow flag is raised. The numerical error guarantee is
    only asserted for frames without accumulator overflow.
    """

    def __init__(self, error_budget_q30: int, accumulator_width: int = 48) -> None:
        if error_budget_q30 < 0:
            raise ValueError("error budget must be non-negative")
        if accumulator_width < 33:
            raise ValueError("accumulator width must be at least 33 bits")
        self.error_budget_q30 = error_budget_q30
        self.accumulator_width = accumulator_width
        self.reset_frame()

    def reset_frame(self) -> None:
        self.accumulator_q30 = 0
        self.error_spent_q30 = 0
        self.exact_accumulator_q30 = 0
        self.overflow = False

    def step(self, a: int, b: int) -> MACStep:
        _check_operand(a)
        _check_operand(b)

        precision, bound = select_precision(
            a, b, self.error_budget_q30, self.error_spent_q30
        )
        qa = quantize_q15(a, precision)
        qb = quantize_q15(b, precision)
        product = qa * qb

        candidate = self.accumulator_q30 + product
        signed_min = -(1 << (self.accumulator_width - 1))
        signed_max = (1 << (self.accumulator_width - 1)) - 1
        if not self.overflow:
            if candidate < signed_min or candidate > signed_max:
                self.overflow = True
            else:
                self.accumulator_q30 = candidate

        self.error_spent_q30 += bound
        if self.error_spent_q30 > self.error_budget_q30:
            raise AssertionError("precision policy exceeded the configured error budget")

        self.exact_accumulator_q30 += a * b
        return MACStep(
            precision=precision,
            quantized_a_q15=qa,
            quantized_b_q15=qb,
            product_q30=product,
            error_bound_q30=bound,
            accumulator_q30=self.accumulator_q30,
            error_spent_q30=self.error_spent_q30,
            overflow=self.overflow,
        )

    @property
    def absolute_accumulation_error_q30(self) -> int:
        return abs(self.exact_accumulator_q30 - self.accumulator_q30)
