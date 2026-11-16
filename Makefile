PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp

RTL_SOURCES = \
	rtl/precision_tiled_multiplier.sv \
	rtl/error_bound_estimator.sv \
	rtl/precision_controller.sv \
	rtl/operand_quantizer.sv \
	rtl/apex_mac_top.sv

.PHONY: test model-test rtl-test rtl-directed-test rtl-random-test rtl-isolation-test rtl-tiled-test rtl-tiled-isolation-test rtl-tiled-exhaustive-test activity-test formal-test clean

test: model-test rtl-test

model-test:
	$(PYTHON) -m unittest discover -s tests -v

rtl-test: rtl-directed-test rtl-random-test rtl-isolation-test rtl-tiled-test rtl-tiled-isolation-test rtl-tiled-exhaustive-test activity-test

rtl-directed-test:
	mkdir -p build
	$(IVERILOG) -g2012 -s tb_apex_mac -o build/tb_apex_mac $(RTL_SOURCES) tb/tb_apex_mac.sv
	$(VVP) build/tb_apex_mac

rtl-random-test:
	mkdir -p build
	$(IVERILOG) -g2012 -s tb_apex_mac_random -o build/tb_apex_mac_random $(RTL_SOURCES) tb/tb_apex_mac_random.sv
	$(VVP) build/tb_apex_mac_random

rtl-isolation-test:
	mkdir -p build
	$(IVERILOG) -g2012 -Ptb_apex_mac.ENABLE_OPERAND_ISOLATION=1 -s tb_apex_mac -o build/tb_apex_mac_iso $(RTL_SOURCES) tb/tb_apex_mac.sv
	$(VVP) build/tb_apex_mac_iso
	$(IVERILOG) -g2012 -Ptb_apex_mac_random.ENABLE_OPERAND_ISOLATION=1 -s tb_apex_mac_random -o build/tb_apex_mac_random_iso $(RTL_SOURCES) tb/tb_apex_mac_random.sv
	$(VVP) build/tb_apex_mac_random_iso

rtl-tiled-test:
	mkdir -p build
	$(IVERILOG) -g2012 -Ptb_apex_mac.USE_TILED_MULTIPLIER=1 -s tb_apex_mac -o build/tb_apex_mac_tiled $(RTL_SOURCES) tb/tb_apex_mac.sv
	$(VVP) build/tb_apex_mac_tiled
	$(IVERILOG) -g2012 -Ptb_apex_mac_random.USE_TILED_MULTIPLIER=1 -s tb_apex_mac_random -o build/tb_apex_mac_random_tiled $(RTL_SOURCES) tb/tb_apex_mac_random.sv
	$(VVP) build/tb_apex_mac_random_tiled

rtl-tiled-isolation-test:
	mkdir -p build
	$(IVERILOG) -g2012 -Ptb_apex_mac.ENABLE_OPERAND_ISOLATION=1 -Ptb_apex_mac.USE_TILED_MULTIPLIER=1 -s tb_apex_mac -o build/tb_apex_mac_tiled_iso $(RTL_SOURCES) tb/tb_apex_mac.sv
	$(VVP) build/tb_apex_mac_tiled_iso
	$(IVERILOG) -g2012 -Ptb_apex_mac_random.ENABLE_OPERAND_ISOLATION=1 -Ptb_apex_mac_random.USE_TILED_MULTIPLIER=1 -s tb_apex_mac_random -o build/tb_apex_mac_random_tiled_iso $(RTL_SOURCES) tb/tb_apex_mac_random.sv
	$(VVP) build/tb_apex_mac_random_tiled_iso

rtl-tiled-exhaustive-test:
	mkdir -p build
	$(IVERILOG) -g2012 -s tb_precision_tiled_multiplier_exhaustive -o build/tb_precision_tiled_multiplier_exhaustive rtl/precision_tiled_multiplier.sv tb/tb_precision_tiled_multiplier_exhaustive.sv
	$(VVP) build/tb_precision_tiled_multiplier_exhaustive

activity-test:
	bash scripts/run_activity_comparison.sh

formal-test:
	bash formal/run_arithmetic_proof.sh

clean:
	rm -rf build __pycache__ models/__pycache__ tests/__pycache__
