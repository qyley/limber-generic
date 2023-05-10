/*----------------------------------------------------------------
| Convert N bit THERMOMETER code to log2(N+1) bit BINARY code.
| for example: 
| 000_0000 -> 000
| 000_0001 -> 001
| 000_0011 -> 010
| 000_0111 -> 011
| ...
| 111_1111 -> 111
| For the sake of a simple circuit structure, we don't consider illegal input.
| This module first convert THERMOMETER code to ONEHOT code using a `gnrc_therm2onehot`
| Then convert the ONEHOT code to BINARY code using a `gnrc_onehot2bin`
| See more in `gnrc_therm2onehot.sv` and `gnrc_onehot2bin.sv`
-----------------------------------------------------------------*/
module gnrc_therm2bin #(
    /* thermometer code width @range: ">=1" */
    parameter int unsigned N = 3,
    /* binary code bit width (auto-gen, do **NOT** change) @range: "$clog2(N+1)+(N==1)" */
    parameter int unsigned M = $clog2(N+1) + (N==1)
)(
    /* thermometer code input */
    input  logic [N-1:0] therm_i,
    /* binary code output */
    output logic [M-1:0] bin_o
);

    logic [N:0] onehot_t;
    
    gnrc_therm2onehot #(.N(N)) inst_gnrc_therm2onehot (.therm_i(therm_i), .onehot_o(onehot_t));

    gnrc_onehot2bin #(.N(N+1)) inst_gnrc_onehot2bin (.onehot_i(onehot_t), .bin_o(bin_o));

endmodule