// Bindable SystemVerilog Assertions for APEX-MAC.
// Compile this file with a simulator/formal tool that supports concurrent SVA.
// The default Icarus smoke flow intentionally does not compile this checker.
module apex_mac_sva_checker (
    input logic clk,
    input logic rst_n,
    input logic frame_start,
    input logic accepted,
    input logic in_ready,
    input logic out_valid,
    input logic [47:0] error_budget_q30,
    input logic [47:0] error_spent_q30,
    input logic [47:0] bound_int4_q30,
    input logic [47:0] bound_int8_q30,
    input logic [47:0] selected_error_bound_q30,
    input logic [1:0] selected_precision,
    input logic [47:0] accumulator_q30,
    input logic overflow,
    input logic budget_violation,
    input logic isolation_enabled,
    input logic signed [15:0] multiplier_operand_a,
    input logic signed [15:0] multiplier_operand_b,
    input logic signed [15:0] quantized_a,
    input logic signed [15:0] quantized_b
);
    logic past_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            past_valid <= 1'b0;
        else
            past_valid <= 1'b1;
    end

    default clocking cb @(posedge clk); endclocking

    ap_out_valid_matches_previous_accept:
        assert property (disable iff (!rst_n)
            past_valid |-> out_valid == $past(accepted));

    ap_frame_start_blocks_input:
        assert property (disable iff (!rst_n)
            frame_start |-> !in_ready);

    ap_int4_fits_remaining_budget:
        assert property (disable iff (!rst_n)
            selected_precision == 2'b00 |->
            (error_spent_q30 <= error_budget_q30) &&
            (bound_int4_q30 <= error_budget_q30 - error_spent_q30) &&
            (selected_error_bound_q30 == bound_int4_q30));

    ap_int8_fits_remaining_budget:
        assert property (disable iff (!rst_n)
            selected_precision == 2'b01 |->
            (error_spent_q30 <= error_budget_q30) &&
            (bound_int4_q30 > error_budget_q30 - error_spent_q30) &&
            (bound_int8_q30 <= error_budget_q30 - error_spent_q30) &&
            (selected_error_bound_q30 == bound_int8_q30));

    ap_int16_has_zero_error_cost:
        assert property (disable iff (!rst_n)
            selected_precision == 2'b10 |-> selected_error_bound_q30 == 48'd0);

    ap_error_spent_monotonic:
        assert property (disable iff (!rst_n)
            (past_valid && !frame_start && $past(!frame_start)) |->
            error_spent_q30 >= $past(error_spent_q30));

    // A stable budget must remain satisfied after an accepted operation,
    // provided the budget was not already below previously spent error.
    ap_budget_safety_when_budget_stable:
        assert property (disable iff (!rst_n)
            (past_valid &&
             $past(accepted && (error_spent_q30 <= error_budget_q30)) &&
             $stable(error_budget_q30)) |->
            error_spent_q30 <= error_budget_q30);

    ap_overflow_sticky:
        assert property (disable iff (!rst_n || frame_start)
            overflow |=> overflow);

    ap_frame_start_clears_state:
        assert property (disable iff (!rst_n)
            frame_start |=> (accumulator_q30 == 48'd0) &&
                            (error_spent_q30 == 48'd0) &&
                            !overflow && !budget_violation);

    // Operand-isolation contract. In the default implementation the
    // multiplier follows the quantized operands; in isolation mode it is
    // held at zero when no input transaction is accepted.
    ap_isolated_multiplier_inputs_zero_when_idle:
        assert property (disable iff (!rst_n)
            (isolation_enabled && !accepted) |->
            (multiplier_operand_a == 16'sd0) &&
            (multiplier_operand_b == 16'sd0));

    ap_isolated_multiplier_inputs_follow_quantized_when_active:
        assert property (disable iff (!rst_n)
            (isolation_enabled && accepted) |->
            (multiplier_operand_a == quantized_a) &&
            (multiplier_operand_b == quantized_b));

    ap_nonisolated_multiplier_inputs_follow_quantized:
        assert property (disable iff (!rst_n)
            (!isolation_enabled) |->
            (multiplier_operand_a == quantized_a) &&
            (multiplier_operand_b == quantized_b));
endmodule

bind apex_mac_top apex_mac_sva_checker u_apex_mac_sva_checker (
    .clk(clk),
    .rst_n(rst_n),
    .frame_start(frame_start),
    .accepted(accepted),
    .in_ready(in_ready),
    .out_valid(out_valid),
    .error_budget_q30(error_budget_q30),
    .error_spent_q30(error_spent_q30),
    .bound_int4_q30(bound_int4_q30),
    .bound_int8_q30(bound_int8_q30),
    .selected_error_bound_q30(selected_error_bound_q30),
    .selected_precision(selected_precision),
    .accumulator_q30(accumulator_q30),
    .overflow(overflow),
    .budget_violation(budget_violation),
    .isolation_enabled(ENABLE_OPERAND_ISOLATION),
    .multiplier_operand_a(multiplier_operand_a),
    .multiplier_operand_b(multiplier_operand_b),
    .quantized_a(quantized_a),
    .quantized_b(quantized_b)
);
