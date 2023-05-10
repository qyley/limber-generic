/*----------------------------------------------------------------
 A Simple shift register with ICG for arbitrary depth and types.
-----------------------------------------------------------------*/
`include "gnrc_ff.svh"
module gnrc_shift_reg_gated #(
  /* the number of FF @range: ">=1" */
  parameter int unsigned DEPTH = 32'd8,
  /* data type @range: "logic(default)" */
  parameter type         DTYPE = logic
) (
  /* Clock */
  input  logic clk_i,
  /* Asynchronous reset active low */
  input  logic rst_ni,
  /* Synchronous clear all data*/
  input  logic flush_i,
  /* valid in */
  input  logic valid_i,
  /* data in */
  input  DTYPE data_i,
  /* valid out */
  output logic valid_o,
  /* data out */
  output DTYPE data_o
);

  // Register of depth 0 is a wire.
  if (DEPTH == 0) begin : gen_pass_through

    assign valid_o = valid_i;
    assign data_o  = data_i;

  // It's a shift register if depth is greater than 0
  end else begin : gen_shift_reg

    logic [DEPTH-1 : 0] valid_d, valid_q;
    DTYPE [DEPTH-1 : 0] data_d, data_q;

    for (genvar i = 0; i < DEPTH; i++) begin : gen_regs

      // Prepare D port for each shift register.
      if (i == 0) begin : gen_shift_in
        assign valid_d[i] = flush_i ? 'b0 : valid_i;
        assign data_d[i]  = data_i;
      end else begin : gen_shift
        assign valid_d[i] = flush_i ? 'b0 : valid_q[i-1];
        assign data_d[i]  = data_q[i-1];
      end

      // shift valid flag without clock gate
      `gnrc_ffarn(clk_i, rst_ni, valid_d[i], valid_q[i])

      // Gate each shift register with a valid flag to enable the synthsis tools to insert ICG for
      // better power comsumption.
      `gnrc_fflarn(clk_i, rst_ni, valid_d[i], data_d[i], data_q[i])
    end

    // Output the shifted result.
    assign valid_o = valid_q[DEPTH-1];
    assign data_o  = data_q[DEPTH-1];

  end

endmodule
