#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build/activity"
mkdir -p "${BUILD_DIR}"
cd "${ROOT_DIR}"

RTL_SOURCES=(
  rtl/error_bound_estimator.sv
  rtl/precision_controller.sv
  rtl/operand_quantizer.sv
  rtl/apex_mac_top.sv
)

iverilog -g2012 -Ptb_apex_mac_activity.ENABLE_OPERAND_ISOLATION=0 \
  -s tb_apex_mac_activity -o "${BUILD_DIR}/activity_baseline" \
  "${RTL_SOURCES[@]}" tb/tb_apex_mac_activity.sv
vvp "${BUILD_DIR}/activity_baseline"

iverilog -g2012 -Ptb_apex_mac_activity.ENABLE_OPERAND_ISOLATION=1 \
  -s tb_apex_mac_activity -o "${BUILD_DIR}/activity_isolated" \
  "${RTL_SOURCES[@]}" tb/tb_apex_mac_activity.sv
vvp "${BUILD_DIR}/activity_isolated"

python3 scripts/analyze_operand_activity.py \
  --baseline "${BUILD_DIR}/activity_baseline.vcd" \
  --isolated "${BUILD_DIR}/activity_isolated.vcd" \
  --output "${BUILD_DIR}/operand_activity.csv"
