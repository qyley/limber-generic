/*----------------------------------------------------------------
| Convert N bit ONEHOT code to N-1 bit THERMOMETER code.
| for example: 
| 0000_0001 -> 000_0000
| 0000_0010 -> 000_0001
| 0000_0100 -> 000_0011
| 0000_1000 -> 000_0111
| ...
| 1000_0000 -> 111_1111
| For the sake of a simple circuit structure, we don't consider illegal input.
| This module instantiate a `gnrc_lzc_therm`, see more in `gnrc_lzc_therm.sv`
-----------------------------------------------------------------*/
module gnrc_onehot2therm #(
    /* one-hot code width @range: ">=1" */
    parameter int unsigned N = 4,
    /* thermometer code bit width (auto-gen, do **NOT** change) @range: "N-1+(N==1)" */
    parameter int unsigned M = N-1+(N==1)
)(
    /* one-hot code input */
    input  logic [N-1:0] onehot_i,
    /* thermometer code output */
    output logic [M-1:0] therm_o
);

    if(N==1)begin
        assign therm_o = 1'b0;
    end
    else begin
        logic [N-1:0] therm_t;
        gnrc_lzc_therm #(.N(N)) inst_gnrc_lzc_therm (.vec_i(onehot_i), .therm_o(therm_t));
        assign therm_o = therm_t[M-1:0];
    end
    

endmodule