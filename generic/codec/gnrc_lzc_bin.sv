/*----------------------------------------------------------------
| qyley<qyley@foxmail.com>
| find a new way to implement lzc, see also `gnrc_lzc.sv`
|
| This implement firstly convert input vector into a thermometer code style(see `gnrc_lzc_therm.sv`)
| Then convert the thermometer code into binary code(see `gnrc_therm2bin`)
| Finally takes the MSB as the `empty_o` ane the rest as `cnt_o`
|
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

module gnrc_lzc_bin #(
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

    logic [WIDTH-1:0] therm_t;

    gnrc_lzc_therm #(.N(WIDTH)) inst_gnrc_lzc_therm (.vec_i(in_i), .therm_o(therm_t));

    logic [CNT_WIDTH-1:0] bin_t;

    gnrc_therm2bin #(.N(WIDTH-1)) inst_gnrc_therm2bin (.therm_i(therm_t[WIDTH-2:0]), .bin_o(bin_t));

    assign cnt_o = bin_t;
    assign empty_o = therm_t[WIDTH-1];
  end

// pragma translate_off
`ifndef VERILATOR
  initial begin: validate_params
    assert (WIDTH >= 1)
      else $fatal(1, "The WIDTH must at least be one bit wide!");
  end
`endif
// pragma translate_on

endmodule : gnrc_lzc_bin
