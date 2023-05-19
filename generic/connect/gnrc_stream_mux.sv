/*----------------------------------------------------------------
| Stream Multiplexer
| Arbitrate N AXI-stream-like input to single AXI-stream-like output.
| Arbitration will be switched after the last data of transaction.
-----------------------------------------------------------------*/
module gnrc_stream_mux #(
    /* Number of inputs port. @range: ">=1"*/
    parameter int N = 1,
    /* data type of each port. @range: "logic"*/
    parameter type DTYPE = logic,
    /* Mode of arbitration. see `gnrc_arbiter` for detail. </br>
    0: Fix-priority (LSB has the most priority) </br>
    1: Unfair round-robin (i.e. depth=0) </br>
    2: Fair round-robin without look-ahead (i.e. depth=1) </br>
    3: Fair round-robin with look-ahead (i.e. depth=2)
    @range: "{0,1,2,3}"*/
    parameter bit [1:0] ARB_MODE = 0,
    /* source address bit width of manager port (auto-gen, do **NOT** change). @range: "$clog2(N)"*/
    parameter int AW = $clog2(N)

) (
    /* Clock, positive edge triggered. */
    input logic             clk_i,
    /* Asynchronous reset, active low. */
    input logic             rst_ni,
    /* Clears the arbiter state. Only used if `ARB_MODE` is 0. */
    input logic             flush_i,
    /* Subordinate ports for input data. */
    input DTYPE [N-1:0]     data_i,
    /* Subordinate ports for valid flag of input data. */
    input logic [N-1:0]     valid_i,
    /* Subordinate ports for last flag of input data. */
    input logic [N-1:0]     last_i,
    /* Subordinate ports for ready flag of input data. */
    output logic [N-1:0]    ready_o,

    /* Manager port for output data. */
    output DTYPE            data_o,
    /* Manager port for valid flag of output data. */
    output logic            valid_o,
    /* Manager port for last flag of output data. */
    output logic            last_o,
    /* Manager port for source address of output data. */
    output logic [AW-1:0]   id_o,
    /* Manager port for ready flag of output data. */
    input logic             ready_i
);

    logic lock_o;
    assign last_o = ~lock_o;

    gnrc_arbiter #(
        .N(N),
        .EXT_RR(ARB_MODE==0),
        .LEAKY(1),
        .DEPTH((ARB_MODE==0) ? 0 : ARB_MODE-1),
        .DTYPE(DTYPE)
    ) inst_gnrc_arbiter (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .flush_i (flush_i),
        .rr_i    ({N{1'b0}}),
        .req_i   (valid_i),
        .lock_i  (~last_i),
        .gnt_o   (ready_o),
        .data_i  (data_i),
        .req_o   (valid_o),
        .lock_o  (lock_o),
        .data_o  (data_o),
        .idx_o   (id_o),
        .gnt_i   (ready_i)
    );

// pragma translate_off
`ifndef VERILATOR
    initial begin: p_assertions
        assert (N >= 1) else $fatal (1, "The number of inputs must be at least 1!");
    end
`endif
// pragma translate_on

endmodule