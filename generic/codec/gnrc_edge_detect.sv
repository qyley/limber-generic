/*----------------------------------------------------------------
| edge detect
----------------------------------------------------------------*/
module gnrc_edge_detect (
    /* clock input */
    input  logic clk_i,
    /* asynchronous low-active reset input */
    input  logic rst_ni,
    /* signal input */
    input  logic d_i,
    /* rise esge detect output */
    output logic r_o,
    /* fall esge detect output */
    output logic f_o
);

    logic d_r;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            d_r <= 'b0;
        end else begin
            d_r <= d_i;
        end
    end

    assign r_o = d_i&~d_r;
    assign f_o = ~d_i&d_r;

endmodule