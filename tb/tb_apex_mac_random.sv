module tb_apex_mac_random #(parameter bit ENABLE_OPERAND_ISOLATION = 1'b0,
    parameter bit USE_TILED_MULTIPLIER = 1'b0);
    logic clk = 1'b0;
    logic rst_n = 1'b1;
    logic frame_start = 1'b0;
    logic in_valid = 1'b0;
    logic in_ready;
    logic signed [15:0] operand_a = 16'sd0;
    logic signed [15:0] operand_b = 16'sd0;
    logic [47:0] error_budget_q30 = 48'd0;
    logic out_valid;
    logic signed [47:0] accumulator_q30;
    logic [47:0] error_spent_q30;
    logic [1:0] last_precision;
    logic overflow;
    logic budget_violation;

    logic signed [47:0] expected_accumulator;
    logic [47:0] expected_error_spent;
    logic [1:0] expected_precision;
    logic expected_overflow;
    logic expected_budget_violation;

    logic [31:0] rng_state;
    integer transaction_count;

    always #5 clk = ~clk;

    apex_mac_top #(.ENABLE_OPERAND_ISOLATION(ENABLE_OPERAND_ISOLATION),
                   .USE_TILED_MULTIPLIER(USE_TILED_MULTIPLIER)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .frame_start(frame_start),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .error_budget_q30(error_budget_q30),
        .out_valid(out_valid),
        .accumulator_q30(accumulator_q30),
        .error_spent_q30(error_spent_q30),
        .last_precision(last_precision),
        .overflow(overflow),
        .budget_violation(budget_violation)
    );

    function automatic logic signed [15:0] ref_quantize_q15(
        input logic signed [15:0] value,
        input integer precision
    );
        integer shift_amt;
        longint signed magnitude;
        longint signed quotient;
        longint signed remainder_value;
        longint signed half_step;
        longint signed max_code;
        longint signed rounded_signed;
        begin
            if (precision == 16) begin
                ref_quantize_q15 = value;
            end else begin
                shift_amt = 16 - precision;
                magnitude = value;
                if (magnitude < 0)
                    magnitude = -magnitude;

                quotient = magnitude / (64'sd1 <<< shift_amt);
                remainder_value = magnitude - (quotient <<< shift_amt);
                half_step = 64'sd1 <<< (shift_amt - 1);

                if ((remainder_value > half_step) ||
                    ((remainder_value == half_step) && (quotient & 1)))
                    quotient = quotient + 1;

                if (value < 0) begin
                    max_code = 64'sd1 <<< (precision - 1);
                    if (quotient > max_code)
                        quotient = max_code;
                    rounded_signed = -quotient;
                end else begin
                    max_code = (64'sd1 <<< (precision - 1)) - 1;
                    if (quotient > max_code)
                        quotient = max_code;
                    rounded_signed = quotient;
                end

                ref_quantize_q15 = rounded_signed <<< shift_amt;
            end
        end
    endfunction

    function automatic logic [47:0] ref_error_bound_q30(
        input logic signed [15:0] a,
        input logic signed [15:0] b,
        input integer precision
    );
        longint signed a_signed;
        longint signed b_signed;
        longint unsigned abs_sum;
        longint unsigned bound_value;
        integer shift_amt;
        begin
            a_signed = a;
            b_signed = b;
            if (a_signed < 0)
                a_signed = -a_signed;
            if (b_signed < 0)
                b_signed = -b_signed;

            if (precision == 16) begin
                bound_value = 0;
            end else begin
                shift_amt = 16 - precision;
                abs_sum = a_signed + b_signed;
                bound_value =
                    (abs_sum <<< shift_amt) +
                    (64'd1 <<< (32 - 2 * precision));
            end
            ref_error_bound_q30 = bound_value[47:0];
        end
    endfunction

    function automatic logic [31:0] xorshift32(input logic [31:0] value);
        logic [31:0] x;
        begin
            x = value;
            x = x ^ (x << 13);
            x = x ^ (x >> 17);
            x = x ^ (x << 5);
            xorshift32 = x;
        end
    endfunction

    task automatic check_outputs(input string test_name);
        begin
            if (out_valid !== 1'b1)
                $fatal(1, "%s: out_valid was not asserted", test_name);
            if (accumulator_q30 !== expected_accumulator)
                $fatal(1, "%s: accumulator expected %0d got %0d",
                       test_name, expected_accumulator, accumulator_q30);
            if (error_spent_q30 !== expected_error_spent)
                $fatal(1, "%s: error_spent expected %0d got %0d",
                       test_name, expected_error_spent, error_spent_q30);
            if (last_precision !== expected_precision)
                $fatal(1, "%s: precision expected %0d got %0d",
                       test_name, expected_precision, last_precision);
            if (overflow !== expected_overflow)
                $fatal(1, "%s: overflow expected %0b got %0b",
                       test_name, expected_overflow, overflow);
            if (budget_violation !== expected_budget_violation)
                $fatal(1, "%s: budget_violation expected %0b got %0b",
                       test_name, expected_budget_violation, budget_violation);
        end
    endtask

    task automatic reset_frame(input logic [47:0] budget);
        begin
            @(negedge clk);
            frame_start = 1'b1;
            in_valid = 1'b1; // frame_start must suppress this attempted input
            error_budget_q30 = budget;
            #1;
            if (in_ready !== 1'b0)
                $fatal(1, "in_ready must be low during frame_start");
            if (ENABLE_OPERAND_ISOLATION &&
                (dut.multiplier_operand_a !== 16'sd0 ||
                 dut.multiplier_operand_b !== 16'sd0))
                $fatal(1, "operand isolation failed while frame_start blocks acceptance");

            @(posedge clk);
            #1;
            expected_accumulator = 48'sd0;
            expected_error_spent = 48'd0;
            expected_precision = 2'b10;
            expected_overflow = 1'b0;
            expected_budget_violation = 1'b0;

            if (out_valid !== 1'b0 ||
                accumulator_q30 !== 48'sd0 ||
                error_spent_q30 !== 48'd0 ||
                last_precision !== 2'b10 ||
                overflow !== 1'b0 ||
                budget_violation !== 1'b0)
                $fatal(1, "frame_start did not atomically clear state");

            @(negedge clk);
            frame_start = 1'b0;
            in_valid = 1'b0;
        end
    endtask

    task automatic apply_mac(
        input logic signed [15:0] a,
        input logic signed [15:0] b,
        input logic [47:0] budget,
        input string test_name
    );
        logic [47:0] bound4;
        logic [47:0] bound8;
        logic [47:0] selected_bound;
        logic [47:0] remaining_budget;
        logic [1:0] selected_mode;
        logic signed [15:0] qa;
        logic signed [15:0] qb;
        logic signed [31:0] qa_ext;
        logic signed [31:0] qb_ext;
        longint signed product_value;
        longint signed candidate_accumulator;
        longint signed accumulator_min;
        longint signed accumulator_max;
        longint unsigned next_error_spent;
        integer selected_precision_integer;
        begin
            bound4 = ref_error_bound_q30(a, b, 4);
            bound8 = ref_error_bound_q30(a, b, 8);
            selected_mode = 2'b10;
            selected_bound = 48'd0;
            remaining_budget = 48'd0;

            if (expected_error_spent <= budget) begin
                remaining_budget = budget - expected_error_spent;
                if (bound4 <= remaining_budget) begin
                    selected_mode = 2'b00;
                    selected_bound = bound4;
                end else if (bound8 <= remaining_budget) begin
                    selected_mode = 2'b01;
                    selected_bound = bound8;
                end
            end

            case (selected_mode)
                2'b00: selected_precision_integer = 4;
                2'b01: selected_precision_integer = 8;
                default: selected_precision_integer = 16;
            endcase

            qa = ref_quantize_q15(a, selected_precision_integer);
            qb = ref_quantize_q15(b, selected_precision_integer);
            qa_ext = {{16{qa[15]}}, qa};
            qb_ext = {{16{qb[15]}}, qb};
            product_value = qa_ext * qb_ext;

            accumulator_min = -(64'sd1 <<< 47);
            accumulator_max = (64'sd1 <<< 47) - 1;
            candidate_accumulator = expected_accumulator + product_value;

            if (!expected_overflow) begin
                if (candidate_accumulator < accumulator_min ||
                    candidate_accumulator > accumulator_max) begin
                    expected_overflow = 1'b1;
                end else begin
                    expected_accumulator = candidate_accumulator[47:0];
                end
            end

            next_error_spent = expected_error_spent + selected_bound;
            if (next_error_spent > budget) begin
                expected_budget_violation = 1'b1;
            end else begin
                expected_error_spent = next_error_spent[47:0];
            end
            expected_precision = selected_mode;

            @(negedge clk);
            operand_a = a;
            operand_b = b;
            error_budget_q30 = budget;
            in_valid = 1'b1;
            #1;
            if (in_ready !== 1'b1)
                $fatal(1, "%s: DUT unexpectedly not ready", test_name);

            // Check combinational decision signals before the accepting edge.
            // Once the edge updates error_spent_q30, the controller correctly
            // recomputes the decision for the next transaction.
            if (dut.bound_int4_q30 !== bound4)
                $fatal(1, "%s: INT4 bound mismatch", test_name);
            if (dut.bound_int8_q30 !== bound8)
                $fatal(1, "%s: INT8 bound mismatch", test_name);
            if (dut.selected_precision !== selected_mode)
                $fatal(1, "%s: combinational precision decision mismatch", test_name);
            if (dut.selected_error_bound_q30 !== selected_bound)
                $fatal(1, "%s: selected error-bound mismatch", test_name);
            if (dut.quantized_a !== qa || dut.quantized_b !== qb)
                $fatal(1, "%s: quantized operand mismatch", test_name);

            @(posedge clk);
            #1;
            check_outputs(test_name);

            transaction_count = transaction_count + 1;
            @(negedge clk);
            in_valid = 1'b0;
        end
    endtask

    integer frame_index;
    integer sample_index;
    logic signed [15:0] random_a;
    logic signed [15:0] random_b;
    logic [47:0] frame_budget;

    initial begin
        expected_accumulator = 48'sd0;
        expected_error_spent = 48'd0;
        expected_precision = 2'b10;
        expected_overflow = 1'b0;
        expected_budget_violation = 1'b0;
        transaction_count = 0;
        rng_state = 32'hA5C3_19E7;

        #1 rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Deterministic known-answer checks across all precision modes.
        reset_frame(48'd0);
        apply_mac(16'sd32767, -16'sd12345, 48'd0, "exact INT16 fallback");

        reset_frame(48'd577536);
        apply_mac(16'sd1000, 16'sd1000, 48'd577536, "INT8 exact budget fit");

        reset_frame(48'd100000000);
        apply_mac(16'sd4096, 16'sd4096, 48'd100000000, "INT4 selection");

        // A budget reduction below previously spent error must force INT16
        // and raise the sticky budget-violation status.
        reset_frame(48'd50000000);
        apply_mac(16'sd1000, 16'sd1000, 48'd50000000, "budget reduction setup");
        apply_mac(16'sd1000, 16'sd1000, 48'd0, "budget reduction violation");
        apply_mac(16'sd1000, 16'sd1000, 48'd50000000, "budget restored");

        // Four reproducible random frames exercise all precision policies.
        for (frame_index = 0; frame_index < 4; frame_index = frame_index + 1) begin
            case (frame_index)
                0: frame_budget = 48'd0;
                1: frame_budget = 48'd1000000;
                2: frame_budget = 48'd25000000;
                default: frame_budget = 48'd400000000;
            endcase
            reset_frame(frame_budget);

            for (sample_index = 0; sample_index < 64; sample_index = sample_index + 1) begin
                rng_state = xorshift32(rng_state);
                if ((sample_index % 4) == 0)
                    random_a = {{4{rng_state[11]}}, rng_state[11:0]};
                else
                    random_a = $signed(rng_state[15:0]);

                rng_state = xorshift32(rng_state);
                if ((sample_index % 4) == 0)
                    random_b = {{4{rng_state[11]}}, rng_state[11:0]};
                else
                    random_b = $signed(rng_state[15:0]);

                apply_mac(random_a, random_b, frame_budget, "randomized transaction");
            end
        end

        // Exercise signed 48-bit accumulator overflow and sticky hold behavior.
        reset_frame(48'd0);
        @(negedge clk);
        expected_accumulator = 48'sh7FFF_FFFF_FFFF;
        dut.accumulator_q30 = 48'sh7FFF_FFFF_FFFF;
        apply_mac(16'sd32767, 16'sd32767, 48'd0, "positive accumulator overflow");
        apply_mac(16'sd1, 16'sd1, 48'd0, "sticky overflow hold");

        $display("APEX-MAC randomized RTL regression PASSED: %0d transactions",
                 transaction_count);
        $finish;
    end
endmodule
