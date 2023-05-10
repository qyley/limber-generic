/*----------------------------------------------------------------
| a lzc(leading zero counter) but `cnt_o` is encoded by thermometer code
| It is more simpler to implement a lzc in thermometer code than binary code
|
| For example:
|   vec_i = 0000_0000, therm_o = 1111_1111(overflow)
|   vec_i = 0000_0001, therm_o = 00000_000
|   vec_i = 0000_1010, therm_o = 00000_001
|   vec_i = 0010_1000, therm_o = 00000_111
|   vec_i = 1000_0000, therm_o = 01111_111
----------------------------------------------------------------*/
module gnrc_lzc_therm #(
    /* input vector bit width @range: ">=1"*/
    parameter int unsigned N = 8
)(
    /* input vector*/
    input  logic [N-1:0] vec_i,
    /* output leading zero counter by thermometer code*/
    output logic [N-1:0] therm_o
);

    for (genvar i = 0; i < N; i++) begin : gen_il
        assign therm_o[i] = ~(|vec_i[i:0]);
    end

endmodule