/*----------------------------------------------------------------
| Convert N bit GRAY code to N bit BINARY code.
| for example: 
| 1101 -> 1001
| 1111 -> 1010
| 1110 -> 1011
| 1100 -> 1010
-----------------------------------------------------------------*/
module gnrc_gray2bin #(
    /* gray code bit width @range: ">=1" */
    parameter int N = 8
)(
    /* gray code input */
    input  logic [N-1:0] gray_i,
    /* binary code output */
    output logic [N-1:0] bin_o
);
    for (genvar i = 0; i < N; i++)
        assign bin_o[i] = ^gray_i[N-1:i];
endmodule