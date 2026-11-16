#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/reports/generic-synth}"
mkdir -p "${OUT_DIR}"
OUT_DIR="$(cd "${OUT_DIR}" && pwd)"

cd "${ROOT_DIR}"

{
  echo "APEX-MAC generic synthesis comparison"
  echo "UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Git commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
  yosys -V
} | tee "${OUT_DIR}/metadata.txt"

for variant in baseline operand_isolated tiled tiled_isolated; do
  VARIANT_DIR="${OUT_DIR}/${variant}"
  mkdir -p "${VARIANT_DIR}"

  case "${variant}" in
    baseline) ISOLATION=0; TILED=0 ;;
    operand_isolated) ISOLATION=1; TILED=0 ;;
    tiled) ISOLATION=0; TILED=1 ;;
    tiled_isolated) ISOLATION=1; TILED=1 ;;
  esac

  cat > "${VARIANT_DIR}/run.ys" <<EOF
read_verilog -sv rtl/precision_tiled_multiplier.sv rtl/error_bound_estimator.sv rtl/precision_controller.sv rtl/operand_quantizer.sv rtl/apex_mac_top.sv
chparam -set ENABLE_OPERAND_ISOLATION ${ISOLATION} -set USE_TILED_MULTIPLIER ${TILED} apex_mac_top
hierarchy -check -top apex_mac_top
proc
opt
check -assert
tee -o ${VARIANT_DIR}/pre_synth_stat.json stat -json
write_json ${VARIANT_DIR}/pre_synth_netlist.json
synth -top apex_mac_top -flatten
check -assert
tee -o ${VARIANT_DIR}/stat.json stat -json
write_json ${VARIANT_DIR}/netlist.json
EOF

  echo "Synthesizing variant: ${variant} (ENABLE_OPERAND_ISOLATION=${ISOLATION}, USE_TILED_MULTIPLIER=${TILED})"
  yosys -s "${VARIANT_DIR}/run.ys" 2>&1 | tee "${VARIANT_DIR}/yosys.log"
done

echo "Generic synthesis comparison completed."
echo "Reports: ${OUT_DIR}"
echo "NOTE: generic mapped cell counts are not ASIC PPA, timing closure, or signoff."
