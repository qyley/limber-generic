// Copyright 2018 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

/*----------------------------------------------------------------
| OLD lzc description
| A trailing zero counter / leading zero counter.
| Set MODE to 0 for trailing zero counter => cnt_o is the number of trailing zeros (from the LSB)
| Set MODE to 1 for leading zero counter  => cnt_o is the number of leading zeros  (from the MSB)
| If the input does not contain a zero, `empty_o` is asserted. Additionally `cnt_o` contains
| the maximum number of zeros - 1. For example:
|   in_i = 000_0000, empty_o = 1, cnt_o = 6 (mode = 0)
|   in_i = 000_0001, empty_o = 0, cnt_o = 0 (mode = 0)
|   in_i = 000_1000, empty_o = 0, cnt_o = 3 (mode = 0)
| Furthermore, this unit contains a more efficient implementation for Verilator (simulation only).
| This speeds up simulation significantly.

| modify by qyley<qyley@foxmail.com>
| find the unmodified code in https://github.com/qyley/common_cells
- fix the bug that all zero in_i will cause an non-corresponding cnt_o result when WIDTH align/misalign 
  an integer power of 2. now cnt_o will always be 0 when in_i is all zero no matter what WIDTH be.
- since the leading zero counter's input must contain at least 1 bit of digit '1',
  otherwise empty_o will be assert, so the cnt_o actually indicates the bit location
  (i.e. the idx) of first "1", and the empty_o indicates there is no '1' exists in
  in_i, when empty_o = 1, cnt_o ought to be zero.
- so the modified gnrc_lzc's function described as follow:

| NEW lzc description
| A trailing zero counter / leading zero counter (also be a first '1' counter).
| Set MODE to 0 for little-endian => cnt_o is the idx of first '1' from the LSB
| Set MODE to 1 for big-endian  => cnt_o is the idx of first '1' from the MSB
  If the input does not contain a '1', `empty_o` is asserted, and cnt_o is '0' in this case.
| `cnt_o` indicates the idx of first '1', also represents the maximum number of leading zeros.
| Additionally `empty_o` can be seem as a carry bit of `cnt_o` when WIDTH is an integer power of 2.
| For example (in mode = 0):
|   in_i = 0000_0000, empty_o = 1'b1, cnt_o = 3'b000
|   in_i = 0000_0001, empty_o = 1'b0, cnt_o = 3'b000
|   in_i = 0000_1000, empty_o = 1'b0, cnt_o = 3'b011
----------------------------------------------------------------*/
module gnrc_lzc #(
  /* The width of the input vector. @range: ">=1"*/
  parameter int unsigned WIDTH = 16,
  /* Mode selection: 0 -> trailing zero, 1 -> leading zero @range: "{0,1}"*/
  parameter bit          MODE  = 1'b0,
  /* Width of the output signal with the zero count(auto-gen, do **NOT** change). @range: "$clog2(WIDTH)+(WIDTH==1)"*/
  parameter int unsigned CNT_WIDTH = $clog2(WIDTH) + (WIDTH==1)
) (
  /* Input vector to be counted. */
  input  logic [WIDTH-1:0]     in_i,
  /* Count of the leading / trailing zeros. */
  output logic [CNT_WIDTH-1:0] cnt_o,
  /* Counter is empty: Asserted if all bits in in_i are zero. */
  output logic                 empty_o
);

  if (WIDTH == 1) begin : gen_degenerate_lzc

    assign cnt_o[0] = 1'b0;
    assign empty_o = !in_i[0];

  end else begin : gen_lzc

    localparam int unsigned NumLevels = $clog2(WIDTH);

  `ifndef VERILATOR
    // pragma translate_off
    initial begin
      assert(WIDTH > 0) else $fatal(1, "input must be at least one bit wide");
    end
    // pragma translate_on
  `endif

    logic [WIDTH-1:0][NumLevels-1:0] index_lut;
    logic [2**NumLevels-2:0] sel_nodes;
    logic [2**NumLevels-2:0][NumLevels-1:0] index_nodes;

    logic [WIDTH-1:0] in_tmp;

    // reverse vector if required
    always_comb begin : flip_vector
      for (int unsigned i = 0; i < WIDTH; i++) begin
        in_tmp[i] = (MODE) ? in_i[WIDTH-1-i] : in_i[i];
      end
    end

    for (genvar j = 0; unsigned'(j) < WIDTH; j++) begin : g_index_lut
      assign index_lut[j] = (NumLevels)'(unsigned'(j));
    end

    for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : g_levels
      if (unsigned'(level) == NumLevels - 1) begin : g_last_level
        for (genvar k = 0; k < 2 ** level; k++) begin : g_level
          // if two successive indices are still in the vector...
          if (unsigned'(k) * 2 < WIDTH - 1) begin : g_reduce
            assign sel_nodes[2 ** level - 1 + k] = in_tmp[k * 2] | in_tmp[k * 2 + 1];
            assign index_nodes[2 ** level - 1 + k] = (in_tmp[(k * 2) +: 2] == 2'b10)
              ? index_lut[k * 2 + 1] :
                index_lut[k * 2 + 0];
          end
          // if only the first index is still in the vector...
          if (unsigned'(k) * 2 == WIDTH - 1) begin : g_base
            assign sel_nodes[2 ** level - 1 + k] = in_tmp[k * 2];
            assign index_nodes[2 ** level - 1 + k] = index_lut[k * 2];
          end
          // if index is out of range
          if (unsigned'(k) * 2 > WIDTH - 1) begin : g_out_of_range
            assign sel_nodes[2 ** level - 1 + k] = 1'b0;
            assign index_nodes[2 ** level - 1 + k] = '0;
          end
        end
      end else begin : g_not_last_level
        for (genvar l = 0; l < 2 ** level; l++) begin : g_level
          assign sel_nodes[2 ** level - 1 + l] =
              sel_nodes[2 ** (level + 1) - 1 + l * 2] | sel_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
          assign index_nodes[2 ** level - 1 + l] = (sel_nodes[(2 ** (level + 1) - 1 + l * 2 ) +: 2] == 2'b10)
            ? index_nodes[2 ** (level + 1) - 1 + l * 2 + 1] :
              index_nodes[2 ** (level + 1) - 1 + l * 2];
        end
      end
    end

    assign cnt_o = NumLevels > unsigned'(0) ? index_nodes[0] : {CNT_WIDTH{1'b0}};
    assign empty_o = NumLevels > unsigned'(0) ? ~sel_nodes[0] : ~(|in_i);

  end : gen_lzc

// pragma translate_off
`ifndef VERILATOR
  initial begin: validate_params
    assert (WIDTH >= 1)
      else $fatal(1, "The WIDTH must at least be one bit wide!");
  end
`endif
// pragma translate_on

endmodule : gnrc_lzc
