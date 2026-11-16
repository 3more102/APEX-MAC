module tb_apex_mac #(parameter bit ENABLE_OPERAND_ISOLATION = 1'b0);
    logic clk = 1'b0;
    logic rst_n = 1'b0;
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

    always #5 clk = ~clk;

    apex_mac_top #(.ENABLE_OPERAND_ISOLATION(ENABLE_OPERAND_ISOLATION)) dut (
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

    task automatic reset_frame;
        begin
            @(negedge clk);
            frame_start = 1'b1;
            in_valid = 1'b0;
            @(negedge clk);
            frame_start = 1'b0;
        end
    endtask

    task automatic apply_mac(
        input logic signed [15:0] a,
        input logic signed [15:0] b,
        input logic [47:0] budget
    );
        begin
            @(negedge clk);
            operand_a = a;
            operand_b = b;
            error_budget_q30 = budget;
            in_valid = 1'b1;
            @(posedge clk);
            #1;
            if (!out_valid)
                $fatal(1, "out_valid did not assert for accepted input");
            @(negedge clk);
            in_valid = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // INT4: a=b=0.125 are exactly representable in Q1.3.
        reset_frame();
        apply_mac(16'sd4096, 16'sd4096, 48'd100000000);
        if (last_precision !== 2'b00)
            $fatal(1, "expected INT4 mode, got %b", last_precision);
        if (dut.bound_int4_q30 !== 48'd50331648)
            $fatal(1, "INT4 error bound mismatch: %0d", dut.bound_int4_q30);
        if (accumulator_q30 !== 48'sd16777216)
            $fatal(1, "INT4 product mismatch: %0d", accumulator_q30);
        if (budget_violation)
            $fatal(1, "unexpected budget violation in INT4 test");

        // INT8: INT4 bound does not fit, INT8 bound fits exactly.
        reset_frame();
        apply_mac(16'sd1000, 16'sd1000, 48'd577536);
        if (last_precision !== 2'b01)
            $fatal(1, "expected INT8 mode, got %b", last_precision);
        if (dut.bound_int8_q30 !== 48'd577536)
            $fatal(1, "INT8 error bound mismatch: %0d", dut.bound_int8_q30);
        if (accumulator_q30 !== 48'sd1048576)
            $fatal(1, "INT8 product mismatch: %0d", accumulator_q30);

        // INT16 exact fallback when the error budget is zero.
        reset_frame();
        apply_mac(16'sd32767, -16'sd12345, 48'd0);
        if (last_precision !== 2'b10)
            $fatal(1, "expected INT16 mode, got %b", last_precision);
        if (accumulator_q30 !== -48'sd404508615)
            $fatal(1, "INT16 product mismatch: %0d", accumulator_q30);
        if (error_spent_q30 !== 48'd0)
            $fatal(1, "INT16 mode must not spend error budget");

        // Verify negative and positive ties-to-even in the INT4 quantizer.
        reset_frame();
        apply_mac(16'sd2048, 16'sd6144, 48'd120000000);
        if (last_precision !== 2'b00)
            $fatal(1, "expected INT4 mode for rounding test");
        if (dut.quantized_a !== 16'sd0 || dut.quantized_b !== 16'sd8192)
            $fatal(1, "INT4 ties-to-even quantization mismatch");

        // Two INT8 operations exhaust the frame budget; the third must
        // fall back to exact INT16 without increasing error_spent_q30.
        reset_frame();
        apply_mac(16'sd1000, 16'sd1000, 48'd1155072);
        if (last_precision !== 2'b01 || error_spent_q30 !== 48'd577536)
            $fatal(1, "first budgeted transaction did not select INT8");
        apply_mac(16'sd1000, 16'sd1000, 48'd1155072);
        if (last_precision !== 2'b01 || error_spent_q30 !== 48'd1155072)
            $fatal(1, "second budgeted transaction did not consume remaining budget");
        apply_mac(16'sd1000, 16'sd1000, 48'd1155072);
        if (last_precision !== 2'b10 || error_spent_q30 !== 48'd1155072)
            $fatal(1, "third transaction should fall back to exact INT16");
        if (accumulator_q30 !== 48'sd3097152)
            $fatal(1, "multi-transaction accumulation mismatch: %0d", accumulator_q30);
        if (budget_violation)
            $fatal(1, "budget controller raised an unexpected violation");

        // An externally reduced budget below already-spent error must be
        // detected. The controller switches to exact INT16 and preserves
        // the prior error-spent count while raising sticky budget_violation.
        reset_frame();
        apply_mac(16'sd1000, 16'sd1000, 48'd577536);
        if (last_precision !== 2'b01 || error_spent_q30 !== 48'd577536)
            $fatal(1, "setup for budget-reduction test failed");
        apply_mac(16'sd1000, 16'sd1000, 48'd0);
        if (last_precision !== 2'b10)
            $fatal(1, "budget reduction should force exact INT16");
        if (!budget_violation)
            $fatal(1, "budget reduction was not reported");
        if (error_spent_q30 !== 48'd577536)
            $fatal(1, "budget violation must not rewrite the spent-error counter");

        $display("APEX-MAC RTL smoke test PASSED");
        $finish;
    end
endmodule
