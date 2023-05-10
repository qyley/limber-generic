/*----------------------------------------------------------------
| Convert N bit BINARY code to N bit GRAY code.
| for example: 
| 1001 -> 1101
| 1010 -> 1111
| 1011 -> 1110
| 1100 -> 1010
-----------------------------------------------------------------*/
module gnrc_bin2gray #(
    /* Binary code bit width @range: ">=1" */
    parameter int N = 8
)(
    /* binary code input */
    input  logic [N-1:0] bin_i,
    /* gray code output */
    output logic [N-1:0] gray_o
);
    assign gray_o = bin_i ^ {1'b0,bin_i[N-1:1]};
endmodule