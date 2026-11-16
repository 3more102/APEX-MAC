module error_bound_estimator (
    input  logic signed [15:0] operand_a,
    input  logic signed [15:0] operand_b,
    output logic        [47:0] bound_int4_q30,
    output logic        [47:0] bound_int8_q30
);
    logic signed [16:0] a_ext;
    logic signed [16:0] b_ext;
    logic        [16:0] abs_a;
    logic        [16:0] abs_b;
    logic        [17:0] sum_abs;

    always_comb begin
        a_ext = {operand_a[15], operand_a};
        b_ext = {operand_b[15], operand_b};

        if (a_ext < 0)
            abs_a = $unsigned(-a_ext);
        else
            abs_a = $unsigned(a_ext);

        if (b_ext < 0)
            abs_b = $unsigned(-b_ext);
        else
            abs_b = $unsigned(b_ext);

        sum_abs = {1'b0, abs_a} + {1'b0, abs_b};

        // E_Q30 = (|A| + |B|)*2**(16-p) + 2**(32-2p)
        // p=4: shift 12, constant 2**24.
        bound_int4_q30 = ({{30{1'b0}}, sum_abs} << 12) + 48'd16777216;

        // p=8: shift 8, constant 2**16.
        bound_int8_q30 = ({{30{1'b0}}, sum_abs} << 8) + 48'd65536;
    end
endmodule
