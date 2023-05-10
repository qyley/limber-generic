/*----------------------------------------------------------------
 Simple shift register for arbitrary depth and types
-----------------------------------------------------------------*/
module gnrc_shift_reg #(
    /* the number of FF @range: ">=1" */
    parameter int unsigned DEPTH = 32'd8,
    /* data type @range: "logic(default)" */
    parameter type         DTYPE = logic
)(
    /* Clock */
    input  logic clk_i,
    /* Asynchronous reset active low */
    input  logic rst_ni,
    /* Synchronous clear all data*/
    input  logic flush_i,
    /* serial data input */
    input  DTYPE d_i,
    /* serial data output */
    output DTYPE d_o
);

  // Register of depth 0 is a wire.
  if (DEPTH == 0) begin : gen_pass_through

    assign d_o = d_i;

  // It's a shift register if depth is greater than 0
  end else begin : gen_shift_reg

    DTYPE [DEPTH-1 : 0] data_d, data_q;

    for (genvar i = 0; i < DEPTH; i++) begin : gen_regs

      // Prepare D port for each shift register.
      if (i == 0) begin : gen_shift_in
        assign data_d[i] = flush_i ? 'b0 : d_i;
      end else begin : gen_shift
        assign data_d[i] = flush_i ? 'b0 : data_q[i-1];
      end

      // shift valid flag without clock gate
      `gnrc_ffarn(clk_i, rst_ni, data_d[i], data_q[i])

    end

    // Output the shifted result.
    assign d_o = data_q[DEPTH-1];

  end

endmodule
