#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/reports/formal-arithmetic"
mkdir -p "${OUT_DIR}"
cd "${ROOT_DIR}"

yosys -V | tee "${OUT_DIR}/tool-version.txt"

yosys -p "
read_verilog -formal -sv rtl/error_bound_estimator.sv rtl/precision_controller.sv rtl/operand_quantizer.sv formal/apex_mac_arithmetic_formal.sv
prep -top apex_mac_arithmetic_formal -flatten
check -assert
sat -prove-asserts -verify -timeout 120
" 2>&1 | tee "${OUT_DIR}/formal-proof.log"

echo "APEX-MAC combinational arithmetic proof PASSED."
