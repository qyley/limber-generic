/*----------------------------------------------------------------
| Convert N bit BINARY code to 2^N-1 bit THERMOMETER code.
| for example: 
| 000 -> 000_0000
| 001 -> 000_0001
| 010 -> 000_0011
| 011 -> 000_0111
| ...
| 111 -> 111_1111 
-----------------------------------------------------------------*/
module gnrc_bin2therm #(
    /* binary code bit width @range: ">=1"*/
    parameter int unsigned N = 3,
    /* thermometer code bit width (auto-gen, do **NOT** change) @range: "2^N-1"*/
    parameter int unsigned M = 2 ** N - 1
)(
    /* binary code input */
    input  logic [N-1:0] bin_i,
    /* thermometer code output */
    output logic [M-1:0] therm_o
);

    logic [M:0] onehot_t;
    
    gnrc_bin2onehot #(.N(N)) inst_gnrc_bin2onehot (.bin_i(bin_i), .onehot_o(onehot_t));

    gnrc_onehot2therm #(.N(M+1)) inst_gnrc_onehot2therm (.onehot_i(onehot_t), .therm_o(therm_o));

endmodule