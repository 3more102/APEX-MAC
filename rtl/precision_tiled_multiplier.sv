// Radix-16 digit-tiled signed multiplier.
// Each 16-bit operand is decomposed into four base-16 digits. The top
// digit is signed; the lower three digits are unsigned. Precision mode
// activates only the digit pairs needed by the aligned INT4 / INT8 / INT16
// quantized operands.
module precision_tiled_multiplier (
    input  logic signed [15:0] operand_a,
    input  logic signed [15:0] operand_b,
    input  logic        [1:0]  precision_mode,
    output logic signed [31:0] product
);
    logic [3:0] active_digits;
    logic signed [4:0] a_digits [0:3];
    logic signed [4:0] b_digits [0:3];
    logic signed [8:0] partial_product;
    logic signed [31:0] shifted_partial;
    logic signed [31:0] accumulated_product;
    integer i;
    integer j;

    always_comb begin
        case (precision_mode)
            2'b00: active_digits = 4'b1000; // INT4: signed top digit only
            2'b01: active_digits = 4'b1100; // INT8: top two digits
            default: active_digits = 4'b1111; // INT16: all digits
        endcase

        a_digits[0] = {1'b0, operand_a[3:0]};
        a_digits[1] = {1'b0, operand_a[7:4]};
        a_digits[2] = {1'b0, operand_a[11:8]};
        a_digits[3] = {operand_a[15], operand_a[15:12]};

        b_digits[0] = {1'b0, operand_b[3:0]};
        b_digits[1] = {1'b0, operand_b[7:4]};
        b_digits[2] = {1'b0, operand_b[11:8]};
        b_digits[3] = {operand_b[15], operand_b[15:12]};

        partial_product = 9'sd0;
        shifted_partial = 32'sd0;
        accumulated_product = 32'sd0;

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                if (active_digits[i] && active_digits[j]) begin
                    partial_product = a_digits[i] * b_digits[j];
                    shifted_partial =
                        {{23{partial_product[8]}}, partial_product};
                    shifted_partial = shifted_partial <<< (4 * (i + j));
                    accumulated_product =
                        accumulated_product + shifted_partial;
                end
            end
        end

        product = accumulated_product;
    end
endmodule
