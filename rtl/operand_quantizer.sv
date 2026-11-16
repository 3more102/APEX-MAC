module operand_quantizer (
    input  logic signed [15:0] operand_a,
    input  logic signed [15:0] operand_b,
    input  logic        [1:0]  precision_mode,
    output logic signed [15:0] quantized_a,
    output logic signed [15:0] quantized_b
);
    localparam logic [1:0] PREC_INT4  = 2'b00;
    localparam logic [1:0] PREC_INT8  = 2'b01;
    localparam logic [1:0] PREC_INT16 = 2'b10;

    // Module-local implementation avoids package-import dependencies in
    // synthesis frontends while preserving the shared arithmetic contract.
    function automatic logic signed [15:0] quantize_q15(
        input logic signed [15:0] value,
        input logic [1:0] mode
    );
        integer shift_amt;
        integer magnitude;
        integer quotient;
        integer remainder_value;
        integer half_step;
        integer max_magnitude;
        integer rounded_signed;
        begin
            if (mode == PREC_INT16) begin
                quantize_q15 = value;
            end else begin
                if (mode == PREC_INT4)
                    shift_amt = 12;
                else
                    shift_amt = 8;

                magnitude = $signed(value);
                if (magnitude < 0)
                    magnitude = -magnitude;

                quotient = magnitude >>> shift_amt;
                remainder_value = magnitude - (quotient <<< shift_amt);
                half_step = 1 <<< (shift_amt - 1);

                if ((remainder_value > half_step) ||
                    ((remainder_value == half_step) && (quotient & 1)))
                    quotient = quotient + 1;

                if (value[15]) begin
                    max_magnitude = 1 <<< ((mode == PREC_INT4) ? 3 : 7);
                    if (quotient > max_magnitude)
                        quotient = max_magnitude;
                    rounded_signed = -quotient;
                end else begin
                    max_magnitude = (1 <<< ((mode == PREC_INT4) ? 3 : 7)) - 1;
                    if (quotient > max_magnitude)
                        quotient = max_magnitude;
                    rounded_signed = quotient;
                end

                quantize_q15 = rounded_signed <<< shift_amt;
            end
        end
    endfunction

    always_comb begin
        quantized_a = quantize_q15(operand_a, precision_mode);
        quantized_b = quantize_q15(operand_b, precision_mode);
    end
endmodule
