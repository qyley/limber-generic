/*----------------------------------------------------------------
| Convert N bit BINARY code to 2^N bit ONEHOT code.
| for example: 
| 1001 -> 0000_0010_0000_0000
| 0000 -> 0000_0000_0000_0001
| 1111 -> 1000_0000_0000_0000
-----------------------------------------------------------------*/
module gnrc_bin2onehot #(
    /* binary code bit width @range: ">=1"*/
    parameter int unsigned N = 8,
    /* onehot code bit width (auto-gen, do **NOT** change) @range: "2^N"*/
    parameter int unsigned M = 2 ** N
)(
    /* binary code input */
    input  logic [N-1:0] bin_i,
    /* one-hot code output */
    output logic [M-1:0] onehot_o
);

    for (genvar i = 0; i < M; i++) begin : gen_il
        logic [N-1:0] tmp_i;
        assign tmp_i = i;
        assign onehot_o[i] = bin_i==tmp_i;
    end

endmodule