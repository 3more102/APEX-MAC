PYTHON ?= python3
IVERILOG ?= iverilog
VVP ?= vvp

RTL_SOURCES = \
	rtl/error_bound_estimator.sv \
	rtl/precision_controller.sv \
	rtl/operand_quantizer.sv \
	rtl/apex_mac_top.sv

.PHONY: test model-test rtl-test rtl-directed-test rtl-random-test rtl-isolation-test activity-test clean

test: model-test rtl-test

model-test:
	$(PYTHON) -m unittest discover -s tests -v

rtl-test: rtl-directed-test rtl-random-test rtl-isolation-test activity-test

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

activity-test:
	bash scripts/run_activity_comparison.sh

clean:
	rm -rf build __pycache__ models/__pycache__ tests/__pycache__
