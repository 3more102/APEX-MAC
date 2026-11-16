module apex_mac_top #(
    parameter bit ENABLE_OPERAND_ISOLATION = 1'b0,
    parameter bit USE_TILED_MULTIPLIER = 1'b0
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               frame_start,

    input  logic               in_valid,
    output logic               in_ready,
    input  logic signed [15:0]  operand_a,
    input  logic signed [15:0]  operand_b,
    input  logic        [47:0]  error_budget_q30,

    output logic               out_valid,
    output logic signed [47:0] accumulator_q30,
    output logic        [47:0] error_spent_q30,
    output logic        [1:0]  last_precision,
    output logic               overflow,
    output logic               budget_violation
);
    localparam logic [1:0] PREC_INT16 = 2'b10;

    logic [47:0] bound_int4_q30;
    logic [47:0] bound_int8_q30;
    logic [1:0]  selected_precision;
    logic [47:0] selected_error_bound_q30;

    logic signed [15:0] quantized_a;
    logic signed [15:0] quantized_b;
    logic signed [15:0] multiplier_operand_a;
    logic signed [15:0] multiplier_operand_b;
    logic signed [31:0] product_q30;

    logic signed [48:0] accumulator_sum;
    logic        [48:0] error_spent_sum;
    logic               accepted;

    assign in_ready = rst_n & ~frame_start;
    assign accepted = in_valid & in_ready;

    error_bound_estimator u_error_bound_estimator (
        .operand_a       (operand_a),
        .operand_b       (operand_b),
        .bound_int4_q30  (bound_int4_q30),
        .bound_int8_q30  (bound_int8_q30)
    );

    precision_controller u_precision_controller (
        .error_budget_q30          (error_budget_q30),
        .error_spent_q30           (error_spent_q30),
        .bound_int4_q30            (bound_int4_q30),
        .bound_int8_q30            (bound_int8_q30),
        .selected_precision        (selected_precision),
        .selected_error_bound_q30  (selected_error_bound_q30)
    );

    operand_quantizer u_operand_quantizer (
        .operand_a      (operand_a),
        .operand_b      (operand_b),
        .precision_mode (selected_precision),
        .quantized_a    (quantized_a),
        .quantized_b    (quantized_b)
    );

    // Optional operand isolation holds the multiplier inputs at zero whenever
    // no input transaction is accepted. It does not alter accepted results.
    generate
        if (ENABLE_OPERAND_ISOLATION) begin : g_operand_isolation
            assign multiplier_operand_a = accepted ? quantized_a : 16'sd0;
            assign multiplier_operand_b = accepted ? quantized_b : 16'sd0;
        end else begin : g_no_operand_isolation
            assign multiplier_operand_a = quantized_a;
            assign multiplier_operand_b = quantized_b;
        end
    endgenerate

    generate
        if (USE_TILED_MULTIPLIER) begin : g_tiled_multiplier
            precision_tiled_multiplier u_precision_tiled_multiplier (
                .operand_a      (multiplier_operand_a),
                .operand_b      (multiplier_operand_b),
                .precision_mode (selected_precision),
                .product        (product_q30)
            );
        end else begin : g_inferred_multiplier
            // Signed 16x16 multiply; product_q30 retains all 32 bits.
            assign product_q30 = multiplier_operand_a * multiplier_operand_b;
        end
    endgenerate

    always_comb begin
        accumulator_sum =
            $signed({accumulator_q30[47], accumulator_q30}) +
            $signed({{17{product_q30[31]}}, product_q30});

        error_spent_sum =
            {1'b0, error_spent_q30} + {1'b0, selected_error_bound_q30};
    end

    // One-cycle registered completion pulse. There is no output back-pressure.
    // frame_start has priority and suppresses input acceptance for that cycle.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid        <= 1'b0;
            accumulator_q30  <= 48'sd0;
            error_spent_q30  <= 48'd0;
            last_precision   <= PREC_INT16;
            overflow         <= 1'b0;
            budget_violation <= 1'b0;
        end else if (frame_start) begin
            out_valid        <= 1'b0;
            accumulator_q30  <= 48'sd0;
            error_spent_q30  <= 48'd0;
            last_precision   <= PREC_INT16;
            overflow         <= 1'b0;
            budget_violation <= 1'b0;
        end else begin
            out_valid <= accepted;

            if (accepted) begin
                last_precision <= selected_precision;

                if (!overflow) begin
                    if (accumulator_sum[48] != accumulator_sum[47]) begin
                        overflow <= 1'b1;
                    end else begin
                        accumulator_q30 <= accumulator_sum[47:0];
                    end
                end

                if (error_spent_sum[48] ||
                    (error_spent_sum[47:0] > error_budget_q30)) begin
                    budget_violation <= 1'b1;
                end else begin
                    error_spent_q30 <= error_spent_sum[47:0];
                end
            end
        end
    end
endmodule
