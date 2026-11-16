module precision_controller (
    input  logic [47:0] error_budget_q30,
    input  logic [47:0] error_spent_q30,
    input  logic [47:0] bound_int4_q30,
    input  logic [47:0] bound_int8_q30,
    output logic [1:0]  selected_precision,
    output logic [47:0] selected_error_bound_q30
);
    localparam logic [1:0] PREC_INT4  = 2'b00;
    localparam logic [1:0] PREC_INT8  = 2'b01;
    localparam logic [1:0] PREC_INT16 = 2'b10;

    logic [47:0] remaining_budget_q30;

    always_comb begin
        selected_precision       = PREC_INT16;
        selected_error_bound_q30 = 48'd0;
        remaining_budget_q30     = 48'd0;

        if (error_spent_q30 <= error_budget_q30) begin
            remaining_budget_q30 = error_budget_q30 - error_spent_q30;

            if (bound_int4_q30 <= remaining_budget_q30) begin
                selected_precision       = PREC_INT4;
                selected_error_bound_q30 = bound_int4_q30;
            end else if (bound_int8_q30 <= remaining_budget_q30) begin
                selected_precision       = PREC_INT8;
                selected_error_bound_q30 = bound_int8_q30;
            end
        end
    end
endmodule
