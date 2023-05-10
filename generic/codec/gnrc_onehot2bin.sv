/*----------------------------------------------------------------
| Convert N bit ONEHOT code to log2(N) bit BINARY code.
| for example: 
| 0000_0001 -> 000
| 0000_0010 -> 001
| 1000_0000 -> 111
| For the sake of a simple circuit structure, we don't consider illegal input.
| If input code is not a ONEHOT code, this module also give an output
| It will seem input as a bitwise-or of several discrete ONEHOT code
| And the output will be a bitwise-or of BINARY code converted from
  those discrete ONEHOT code
| for example:
| 0001_0010 can be seem as (0001_0000 | 0000_0010)
| so the output will be (100 | 001) = 101
| And if input is all zero, the output is 0.
| In simulation, input a non ONEHOT code to this module will assert an fatal issue.
-----------------------------------------------------------------*/
module gnrc_onehot2bin #(
    /* one-hot code width @range: ">=1" */
    parameter int unsigned N = 8,
    /* binary code bit width (auto-gen, do **NOT** change) @range: "$clog2(N)+(N==1)" */
    parameter int unsigned M = $clog2(N)+(N==1)
)(
    /* one-hot code input */
    input  logic [N-1:0] onehot_i,
    /* binary code output */
    output logic [M-1:0] bin_o
);

    for (genvar j = 0; j < M; j++) begin : gen_jl

        logic [N-1:0] tmp_mask;
        // deconstruct every binary digit
        for (genvar i = 0; i < N; i++) begin : gen_il
            logic [M-1:0] tmp_i;
            assign tmp_i = i;
            assign tmp_mask[i] = tmp_i[j];
        end

        // reconstruct each binary digit
        assign bin_o[j] = |(tmp_mask & onehot_i);
    end



// pragma translate_off
`ifndef VERILATOR
    assert final ($onehot0(onehot_i)) else
        $fatal(1, "[onehot_to_bin] More than two bit set in the one-hot signal");
`endif
// pragma translate_on
endmodule