module tb_precision_tiled_multiplier_exhaustive;
    logic signed [15:0] operand_a = 16'sd0;
    logic signed [15:0] operand_b = 16'sd0;
    logic [1:0] precision_mode = 2'b10;
    logic signed [31:0] product;

    logic signed [31:0] operand_a_ext;
    logic signed [31:0] operand_b_ext;
    logic signed [31:0] expected_product;
    logic [31:0] rng_state;
    integer i;
    integer j;
    integer checks;

    precision_tiled_multiplier dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .precision_mode(precision_mode),
        .product(product)
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

    task automatic check_product(input string test_name);
        begin
            operand_a_ext = {{16{operand_a[15]}}, operand_a};
            operand_b_ext = {{16{operand_b[15]}}, operand_b};
            expected_product = operand_a_ext * operand_b_ext;
            #1;
            if (product !== expected_product)
                $fatal(1, "%s mismatch: a=%0d b=%0d mode=%b expected=%0d got=%0d",
                       test_name, operand_a, operand_b, precision_mode,
                       expected_product, product);
            checks = checks + 1;
        end
    endtask

    initial begin
        checks = 0;
        rng_state = 32'hC001_D00D;

        // Exhaust all signed INT4 operand-code combinations.
        precision_mode = 2'b00;
        for (i = -8; i <= 7; i = i + 1) begin
            for (j = -8; j <= 7; j = j + 1) begin
                operand_a = i * 4096;
                operand_b = j * 4096;
                check_product("exhaustive INT4");
            end
        end

        // Exhaust all signed INT8 operand-code combinations (65,536 pairs).
        precision_mode = 2'b01;
        for (i = -128; i <= 127; i = i + 1) begin
            for (j = -128; j <= 127; j = j + 1) begin
                operand_a = i * 256;
                operand_b = j * 256;
                check_product("exhaustive INT8");
            end
        end

        // Exercise exact INT16 mode with a reproducible random set.
        precision_mode = 2'b10;
        for (i = 0; i < 10000; i = i + 1) begin
            rng_state = xorshift32(rng_state);
            operand_a = $signed(rng_state[15:0]);
            rng_state = xorshift32(rng_state);
            operand_b = $signed(rng_state[15:0]);
            check_product("random INT16");
        end

        $display("Precision-tiled multiplier exhaustive regression PASSED: %0d products",
                 checks);
        $finish;
    end
endmodule
