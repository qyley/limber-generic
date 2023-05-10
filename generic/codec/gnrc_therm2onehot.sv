/*----------------------------------------------------------------
| Convert N bit THERMOMETER code to N+1 bit ONEHOT code.
| for example: 
| 000_0000 -> 0000_0001
| 000_0001 -> 0000_0010
| 000_0011 -> 0000_0100
| 000_0111 -> 0000_1000
| ...
| 111_1111 -> 1000_0000
| For the sake of a simple circuit structure, we don't consider illegal input.
| onehot_o is given by {1'b0, therm_i} ^ {therm_i, 1'b1}.
-----------------------------------------------------------------*/
module gnrc_therm2onehot #(
    /* thermometer code width @range: ">=1" */
    parameter int unsigned N = 3,
    /* onehot code bit width (auto-gen, do **NOT** change) @range: "N+1" */
    parameter int unsigned M = N+1
)(
    /* thermometer code input */
    input  logic [N-1:0] therm_i,
    /* onehot code output */
    output logic [M-1:0] onehot_o
);

    assign onehot_o = {1'b0, therm_i} ^ {therm_i, 1'b1};

endmodule