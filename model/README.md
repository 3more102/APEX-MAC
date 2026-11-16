# Reference Model

apex_mac_model.py defines the initial signed Q1.15 quantization, Q30 product-error bound, precision-selection policy and single-lane accumulation-window model.

Run tests from the repository root:

    python -m unittest discover -s tests -v

The model uses integer arithmetic so the contract is deterministic and independent of floating-point rounding behavior.
