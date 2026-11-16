module tb_apex_mac_activity #(parameter bit ENABLE_OPERAND_ISOLATION = 1'b0);
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
    logic [31:0] rng_state;
    integer i;

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

    task automatic randomize_operands;
        begin
            rng_state = xorshift32(rng_state);
            operand_a = $signed(rng_state[15:0]);
            rng_state = xorshift32(rng_state);
            operand_b = $signed(rng_state[15:0]);
        end
    endtask

    initial begin
        rng_state = 32'h1357_9BDF;
        if (ENABLE_OPERAND_ISOLATION)
            $dumpfile("build/activity/activity_isolated.vcd");
        else
            $dumpfile("build/activity/activity_baseline.vcd");
        $dumpvars(0, dut);

        #1 rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Idle phase 1: inputs toggle but no transactions are accepted.
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            in_valid = 1'b0;
            randomize_operands();
            #1;
            if (ENABLE_OPERAND_ISOLATION &&
                (dut.multiplier_operand_a !== 16'sd0 ||
                 dut.multiplier_operand_b !== 16'sd0))
                $fatal(1, "isolated multiplier inputs toggled during idle phase");
            if (!ENABLE_OPERAND_ISOLATION &&
                (dut.multiplier_operand_a !== dut.quantized_a ||
                 dut.multiplier_operand_b !== dut.quantized_b))
                $fatal(1, "baseline multiplier inputs did not follow quantized operands");
        end

        // Active phase: accepted transactions exercise the datapath.
        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk);
            in_valid = 1'b1;
            randomize_operands();
            #1;
            if (dut.multiplier_operand_a !== dut.quantized_a ||
                dut.multiplier_operand_b !== dut.quantized_b)
                $fatal(1, "accepted operands were not passed to multiplier");
        end

        // Idle phase 2: inputs continue toggling while the MAC is inactive.
        for (i = 0; i < 256; i = i + 1) begin
            @(negedge clk);
            in_valid = 1'b0;
            randomize_operands();
            #1;
            if (ENABLE_OPERAND_ISOLATION &&
                (dut.multiplier_operand_a !== 16'sd0 ||
                 dut.multiplier_operand_b !== 16'sd0))
                $fatal(1, "isolated multiplier inputs toggled during second idle phase");
        end

        @(negedge clk);
        in_valid = 1'b0;
        $display("Activity trace completed (operand isolation=%0b)",
                 ENABLE_OPERAND_ISOLATION);
        $finish;
    end
endmodule
