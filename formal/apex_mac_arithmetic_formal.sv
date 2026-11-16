// Combinational formal harness for the APEX-MAC arithmetic contract.
// All inputs are symbolic constants. The proof checks every signed Q1.15
// operand pair and every 48-bit budget/spent combination.
module apex_mac_arithmetic_formal;
    (* anyconst *) logic signed [15:0] operand_a;
    (* anyconst *) logic signed [15:0] operand_b;
    (* anyconst *) logic [47:0] error_budget_q30;
    (* anyconst *) logic [47:0] error_spent_q30;

    logic [47:0] bound_int4_q30;
    logic [47:0] bound_int8_q30;
    logic [1:0] selected_precision;
    logic [47:0] selected_error_bound_q30;

    logic signed [15:0] quantized_a_int4;
    logic signed [15:0] quantized_b_int4;
    logic signed [15:0] quantized_a_int8;
    logic signed [15:0] quantized_b_int8;

    logic signed [31:0] exact_product_q30;
    logic signed [31:0] approximate_product_int4_q30;
    logic signed [31:0] approximate_product_int8_q30;
    logic signed [32:0] difference_int4;
    logic signed [32:0] difference_int8;
    logic [32:0] absolute_error_int4;
    logic [32:0] absolute_error_int8;

    error_bound_estimator u_error_bound_estimator (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .bound_int4_q30(bound_int4_q30),
        .bound_int8_q30(bound_int8_q30)
    );

    precision_controller u_precision_controller (
        .error_budget_q30(error_budget_q30),
        .error_spent_q30(error_spent_q30),
        .bound_int4_q30(bound_int4_q30),
        .bound_int8_q30(bound_int8_q30),
        .selected_precision(selected_precision),
        .selected_error_bound_q30(selected_error_bound_q30)
    );

    operand_quantizer u_quantizer_int4 (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .precision_mode(2'b00),
        .quantized_a(quantized_a_int4),
        .quantized_b(quantized_b_int4)
    );

    operand_quantizer u_quantizer_int8 (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .precision_mode(2'b01),
        .quantized_a(quantized_a_int8),
        .quantized_b(quantized_b_int8)
    );

    assign exact_product_q30 = operand_a * operand_b;
    assign approximate_product_int4_q30 =
        quantized_a_int4 * quantized_b_int4;
    assign approximate_product_int8_q30 =
        quantized_a_int8 * quantized_b_int8;

    assign difference_int4 =
        {exact_product_q30[31], exact_product_q30} -
        {approximate_product_int4_q30[31], approximate_product_int4_q30};
    assign difference_int8 =
        {exact_product_q30[31], exact_product_q30} -
        {approximate_product_int8_q30[31], approximate_product_int8_q30};

    assign absolute_error_int4 = difference_int4[32]
        ? $unsigned(-difference_int4) : $unsigned(difference_int4);
    assign absolute_error_int8 = difference_int8[32]
        ? $unsigned(-difference_int8) : $unsigned(difference_int8);

    always @* begin
        // Mathematical contract: conservative bounds dominate actual
        // per-product absolute error for every signed Q1.15 operand pair.
        assert({15'd0, absolute_error_int4} <= bound_int4_q30);
        assert({15'd0, absolute_error_int8} <= bound_int8_q30);
        assert(bound_int8_q30 <= bound_int4_q30);

        // Controller contract: reduced precision is selected only when the
        // corresponding bound fits the remaining budget.
        if (selected_precision == 2'b00) begin
            assert(error_spent_q30 <= error_budget_q30);
            assert(bound_int4_q30 <= error_budget_q30 - error_spent_q30);
            assert(selected_error_bound_q30 == bound_int4_q30);
        end else if (selected_precision == 2'b01) begin
            assert(error_spent_q30 <= error_budget_q30);
            assert(bound_int4_q30 > error_budget_q30 - error_spent_q30);
            assert(bound_int8_q30 <= error_budget_q30 - error_spent_q30);
            assert(selected_error_bound_q30 == bound_int8_q30);
        end else begin
            assert(selected_precision == 2'b10);
            assert(selected_error_bound_q30 == 48'd0);
        end
    end
endmodule
