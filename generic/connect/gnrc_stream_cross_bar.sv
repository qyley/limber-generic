/*----------------------------------------------------------------
| Stream Cross Bar
| Connect ``N_IN`` AXI-stream-like input to ``N_OUT`` AXI-stream-like output
  routed by ``dest_i``.
| Use ``N_OUT`` `gnrc_stream_mux` and ``N_IN`` `gnrc_stream_demux`.
-----------------------------------------------------------------*/
module gnrc_stream_cross_bar #(
    /* Number of Subordinate port (i.e. inputs port). @range: ">=1"*/
    parameter int N_IN = 4,
    /* Number of Manager port (i.e. outputs port). @range: ">=1"*/
    parameter int N_OUT = 4,
    /* data type of each port. @range: "logic"*/
    parameter type DTYPE = logic,
    /* Mode of arbitration. see `gnrc_arbiter` for detail. </br>
    0: Fix-priority (LSB has the most priority) </br>
    1: Unfair round-robin (i.e. depth=0) </br>
    2: Fair round-robin without look-ahead (i.e. depth=1) </br>
    3: Fair round-robin with look-ahead (i.e. depth=2)
    @range: "{0,1,2,3}"*/
    parameter bit [1:0] ARB_MODE = 3,
    /* Bit Map of Connectivity.
    Use a N_IN * N_OUT bit map to set the connectivity between each input and output.
    set the bit of MAP(n,m) to '1' to connect the n-th input to m-th output.
    Full connect as default if this param hasn't been overrided.
    @range: "N_IN*N_OUT matrix of bit {0,1}"*/
    parameter logic[N_IN-1:0][N_OUT-1:0] MAP = -1,
    /* Adds a register slice at each output. @range: "{0,1}*/
    parameter bit OBUF = 1,
    /* Set to 1 to use the private address of `dest_i` and `id_o` for each port. 
    Set to 0 to use a global address of `dest_i` and `id_o` for each port.@range: "{0,1}*/
    parameter bit PRIVATE_ADDR = 0,
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

    // population count
    function automatic int unsigned map_row_popcount (input int n);
        map_row_popcount = 0;
        for(int unsigned i=0; i<N_OUT; i++)begin
            if(MAP[n][i])begin
                map_row_popcount += 1;
            end
        end
        return map_row_popcount;
    endfunction

    function automatic int unsigned map_col_popcount (input int m);
        map_col_popcount = 0;
        for(int unsigned i=0; i<N_IN; i++)begin
            if(MAP[i][m])begin
                map_col_popcount += 1;
            end
        end
        return map_col_popcount;
    endfunction

    typedef struct packed {
        DTYPE tdata;
        logic tlast;
    } demux_data_t;

    typedef struct packed {
        DTYPE tdata;
        logic tlast;
        ID_T tid;
    } mux_data_t;

    // cross bar
    demux_data_t [N_IN-1:0] [N_OUT-1:0] xbar_data;
    logic [N_IN-1:0] [N_OUT-1:0] xbar_valid;
    logic [N_IN-1:0] [N_OUT-1:0] xbar_ready;

    // gen input demux and connect to cross bar
    for (genvar nn=0; nn<N_IN; nn++) begin : gen_input_demux
        localparam nConnect = map_row_popcount(nn);
        localparam nPort = PRIVATE_ADDR ? nConnect : N_OUT;

        if(nConnect==0)begin : gen_no_connect
            assign ready_o[nn] = '0;
        end
        else begin : gen_connect
            demux_data_t demux_data_in;
            assign demux_data_in = '{
                tdata: data_i[nn],
                tlast: last_i[nn]
            };

            demux_data_t [nPort-1:0] demux_data_out;
            logic [nPort-1:0] demux_valid_out;
            logic [nPort-1:0] demux_ready_in;

            gnrc_stream_demux #(
                .N(nPort),
                .DTYPE(demux_data_t)
            ) inst_gnrc_stream_demux (
                .data_i  (demux_data_in),
                .valid_i (valid_i[nn]),
                .dest_i  (dest_i[nn]),
                .ready_o (ready_o[nn]),
                .data_o  (demux_data_out),
                .valid_o (demux_valid_out),
                .ready_i (demux_ready_in)
            );

            if(PRIVATE_ADDR)begin
                always_comb begin
                    int n_idx;
                    n_idx = 0;
                    for(int inp_m=0; inp_m<N_OUT; inp_m++) begin
                        if(MAP[nn][inp_m])begin
                            demux_ready_in[n_idx] = xbar_ready[nn][inp_m];
                            xbar_data[nn][inp_m] = demux_data_out[n_idx];
                            xbar_valid[nn][inp_m] = demux_valid_out[n_idx];
                            n_idx++;
                        end
                    end
                end
            end
            else begin
                always_comb begin
                    for(int inp_m=0; inp_m<N_OUT; inp_m++) begin
                        if(MAP[nn][inp_m])begin
                            demux_ready_in[inp_m] = xbar_ready[nn][inp_m];
                            xbar_data[nn][inp_m] = demux_data_out[inp_m];
                            xbar_valid[nn][inp_m] = demux_valid_out[inp_m];
                        end
                        else begin
                            demux_ready_in[inp_m] = '0;
                        end
                    end
                end
            end
        end
    end

    // gen output mux and connect to cross bar
    for (genvar mm=0; mm<N_OUT; mm++) begin : gen_output_mux
        localparam mConnect = map_col_popcount(mm);
        localparam mPort = PRIVATE_ADDR ? mConnect : N_IN;

        if(mConnect==0)begin : gen_no_connect
            assign data_o[mm] = '0;
            assign valid_o[mm] = '0;
            assign last_o[mm] = '0;
            assign id_o[mm] = '0;
        end
        else begin : gen_connect
            
            DTYPE [mPort-1:0] mux_data_in;
            logic [mPort-1:0] mux_valid_in;
            logic [mPort-1:0] mux_last_in;
            logic [mPort-1:0] mux_ready_out;
            
            mux_data_t mux_data_out;
            logic mux_valid_out;
            logic mux_ready_in;
            
            gnrc_stream_mux #(
                .N(mPort),
                .DTYPE(DTYPE),
                .ARB_MODE(ARB_MODE)
            ) inst_gnrc_stream_mux (
                .clk_i   (clk_i),
                .rst_ni  (rst_ni),
                .flush_i (flush_i),
                .data_i  (mux_data_in),
                .valid_i (mux_valid_in),
                .last_i  (mux_last_in),
                .ready_o (mux_ready_out),
                .data_o  (mux_data_out.tdata),
                .valid_o (mux_valid_out),
                .last_o  (mux_data_out.tlast),
                .id_o    (mux_data_out.tid),
                .ready_i (mux_ready_in)
            );

            mux_data_t slice_data_out;

            gnrc_slice #(
                .FORWARD_Q(OBUF),
                .BACKWARD_Q(OBUF),
                .DTYPE(mux_data_t)
            ) inst_gnrc_slice (
                .clk_i   (clk_i),
                .rst_ni  (rst_ni),
                .flush_i (flush_i),
                .valid_i (mux_valid_out),
                .data_i  (mux_data_out),
                .ready_o (mux_ready_in),
                .valid_o (valid_o[mm]),
                .data_o  (slice_data_out),
                .ready_i (ready_i[mm])
            );

            assign data_o[mm] = slice_data_out.tdata;
            assign last_o[mm] = slice_data_out.tlast;
            assign id_o[mm] = slice_data_out.tid;

            if(PRIVATE_ADDR) begin
                always_comb begin
                    int m_idx;
                    m_idx = 0;
                    for(int oup_n=0; oup_n<N_IN; oup_n++) begin
                        if(MAP[oup_n][mm])begin
                            mux_data_in[m_idx] = xbar_data[oup_n][mm].tdata;
                            mux_last_in[m_idx] = xbar_data[oup_n][mm].tlast;
                            mux_valid_in[m_idx] = xbar_valid[oup_n][mm];
                            xbar_ready[oup_n][mm] = mux_ready_out[oup_n];
                            m_idx++;
                        end
                    end
                end
            end
            else begin
                always_comb begin
                    for(int oup_n=0; oup_n<N_IN; oup_n++) begin
                        if(MAP[oup_n][mm])begin
                            mux_data_in[oup_n] = xbar_data[oup_n][mm].tdata;
                            mux_last_in[oup_n] = xbar_data[oup_n][mm].tlast;
                            mux_valid_in[oup_n] = xbar_valid[oup_n][mm];
                            xbar_ready[oup_n][mm] = mux_ready_out[oup_n];
                        end
                        else begin
                            mux_data_in[oup_n] = '0;
                            mux_last_in[oup_n] = '0;
                            mux_valid_in[oup_n] = '0;
                        end
                    end
                end
            end
        end
    end


endmodule