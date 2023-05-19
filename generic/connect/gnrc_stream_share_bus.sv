/*----------------------------------------------------------------
| Stream Share Bus
| Connect 1 of ``N_IN`` AXI-stream-like input to 1 of ``N_OUT`` AXI-stream-like output,
  routed by `dest_i`.
| use a `gnrc_stream_mux` and a `gnrc_stream_demux`.
-----------------------------------------------------------------*/
module gnrc_stream_share_bus #(
    /* Number of Subordinate port (i.e. inputs port). @range: ">=1"*/
    parameter int N_IN = 1,
    /* Number of Manager port (i.e. outputs port). @range: ">=1"*/
    parameter int N_OUT = 1,
    /* data type of each port. @range: "logic"*/
    parameter type DTYPE = logic,
    /* Mode of arbitration. see `gnrc_arbiter` for detail. </br>
    0: Fix-priority (LSB has the most priority) </br>
    1: Unfair round-robin (i.e. depth=0) </br>
    2: Fair round-robin without look-ahead (i.e. depth=1) </br>
    3: Fair round-robin with look-ahead (i.e. depth=2)
    @range: "{0,1,2,3}"*/
    parameter bit [1:0] ARB_MODE = 0,
    /* Adds a register slice at each output. @range: "{0,1}*/
    parameter bit OBUF = 1,
    /* dest address bit width of each manager port (auto-gen, do **NOT** change). @range: "logic [$clog2(N_OUT)-1:0]"*/
    parameter type DEST_T = logic [$clog2(N_OUT)-1:0],
    /* source address bit width of each subordinate port (auto-gen, do **NOT** change). @range: "logic [$clog2(N_IN)-1:0]"*/
    parameter type ID_T = logic [$clog2(N_IN)-1:0]
) (
    /* Clock, positive edge triggered. */
    input logic             clk_i,
    /* Asynchronous reset, active low. */
    input logic             rst_ni,
    /* Clears the OBUF and arbiter. */
    input logic             flush_i,

    /* Subordinate ports for input data. */
    input DTYPE [N_IN-1:0]     data_i,
    /* Subordinate ports for valid flag of input data. */
    input logic [N_IN-1:0]     valid_i,
    /* Subordinate ports for last flag of input data. */
    input logic [N_IN-1:0]     last_i,
    /* Subordinate ports for destination of input data. */
    input DEST_T [N_IN-1:0]    dest_i,
    /* Subordinate port for ready flag of input data. */
    output logic [N_IN-1:0]    ready_o,

    /* Manager ports for output data. */
    output DTYPE [N_OUT-1:0]    data_o,
    /* Manager ports for valid flag of output data. */
    output logic [N_OUT-1:0]    valid_o,
    /* Manager ports for last flag of output data. */
    output logic [N_OUT-1:0]    last_o,
    /* Manager ports for source address of output data. */
    output ID_T [N_OUT-1:0]     id_o,
    /* Manager ports for ready flag of output data. */
    input logic [N_OUT-1:0]     ready_i
);

    typedef struct packed {
        DTYPE tdata;
        DEST_T tdest;
    } mux_data_t;

    mux_data_t [N_IN-1:0] mux_data_in;
    mux_data_t mux_data_out;
    logic mux_valid_out;
    logic mux_last_out;
    ID_T mux_id_out;
    logic mux_ready_in;

    for(genvar n_s=0; n_s < N_IN; n_s++)begin
        assign mux_data_in[n_s] = '{
            tdata: data_i[n_s],
            tdest: dest_i[n_s]
        };
    end

    gnrc_stream_mux #(
        .N(N_IN),
        .DTYPE(mux_data_t),
        .ARB_MODE(ARB_MODE)
    ) inst_gnrc_stream_mux (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .flush_i (flush_i),
        .data_i  (mux_data_in),
        .valid_i (valid_i),
        .last_i  (last_i),
        .ready_o (ready_o),
        .data_o  (mux_data_out),
        .valid_o (mux_valid_out),
        .last_o  (mux_last_out),
        .id_o    (mux_id_out),
        .ready_i (mux_ready_in)
    );

    typedef struct packed {
        DTYPE tdata;
        logic tlast;
        ID_T tid;
    } demux_data_t;

    demux_data_t demux_data_in;
    demux_data_t [N_OUT-1:0] demux_data_out;
    demux_data_t [N_OUT-1:0] slice_data_out;
    logic [N_OUT-1:0] demux_valid_out;
    logic [N_OUT-1:0] demux_ready_in;

    assign demux_data_in = '{
        tdata: mux_data_out.tdata,
        tlast: mux_last_out,
        tid : mux_id_out
    };



    gnrc_stream_demux #(
        .N(N_OUT),
        .DTYPE(demux_data_t)
    ) inst_gnrc_stream_demux (
        .data_i  (demux_data_in),
        .valid_i (mux_valid_out),
        .dest_i  (mux_data_out.tdest),
        .ready_o (mux_ready_in),
        .data_o  (demux_data_out),
        .valid_o (demux_valid_out),
        .ready_i (demux_ready_in)
    );

    for(genvar n_m=0; n_m < N_OUT; n_m++)begin
        gnrc_slice #(
            .FORWARD_Q(OBUF),
            .BACKWARD_Q(OBUF),
            .DTYPE(demux_data_t)
        ) inst_gnrc_slice (
            .clk_i   (clk_i),
            .rst_ni  (rst_ni),
            .flush_i (flush_i),
            .valid_i (demux_valid_out[n_m]),
            .data_i  (demux_data_out[n_m]),
            .ready_o (demux_ready_in[n_m]),
            .valid_o (valid_o[n_m]),
            .data_o  (slice_data_out[n_m]),
            .ready_i (ready_i[n_m])
        );
        assign data_o[n_m] = slice_data_out[n_m].tdata;
        assign last_o[n_m] = slice_data_out[n_m].tlast;
        assign id_o[n_m] = slice_data_out[n_m].tid;
    end



endmodule