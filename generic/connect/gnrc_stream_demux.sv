/*----------------------------------------------------------------
| Stream DeMultiplexer
| Switch single AXI-stream-like input to
  1 of N AXI-stream-like output by ``dest_i``.
-----------------------------------------------------------------*/
module gnrc_stream_demux #(
    /* Number of inputs port. @range: ">=1"*/
    parameter int N = 1,
    /* data type of each port. @range: "logic"*/
    parameter type DTYPE = logic,
    /* dest address bit width of each port (auto-gen, do **NOT** change). @range: "$clog2(N)"*/
    parameter int AW = $clog2(N)

) (
    /* Subordinate port for input data. */
    input DTYPE             data_i,
    /* Subordinate port for valid flag of input data. */
    input logic             valid_i,
    /* Subordinate port for destination of input data. */
    input logic [AW-1:0]    dest_i,
    /* Subordinate port for ready flag of input data. */
    output logic            ready_o,

    /* Manager ports for output data. */
    output DTYPE [N-1:0]    data_o,
    /* Manager ports for valid flag of output data. */
    output logic [N-1:0]    valid_o,
    /* Manager ports for ready flag of output data. */
    input logic [N-1:0]     ready_i
);

    always_comb begin
        valid_o = '0;
        valid_o[dest_i] = valid_i;
    end

    for(genvar i=0; i<N; i++)begin
        assign data_o[i] = data_i;
    end

    assign ready_o = ready_i[dest_i];

// pragma translate_off
`ifndef VERILATOR
    initial begin: p_assertions
        assert (N >= 1) else $fatal (1, "The number of outputs must be at least 1!");
    end
`endif
// pragma translate_on

endmodule