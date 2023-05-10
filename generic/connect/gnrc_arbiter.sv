/*----------------------------------------------------------------
| Round-Robin and Priority arbitor.
| derived from pulp/common_cell/rr_arb_tree
| modified by qyley(qyley@foxmail.com)
|
| update log:
| - add `lock_i` & `lock_o`, granted requester can assert a `lock_i` signal
|   to prevents the arbiter from changing the arbitration decision in next clock. 
| - remove `LockIn` Parameter, since it can be replaced by `lock_i`
| - Use an intrinsic tree fabric to replace the `lzc` module in original `rr_arb_tree`,
|   making a slightly reduction of timing path and area.
| - add a new `rr_q` updating method, see the parameter `EXT_RR` and `DEPTH`.
-----------------------------------------------------------------*/
module gnrc_arbiter#(
    /* Number of inputs to be arbitrated. @range: ">=1"*/
    parameter int unsigned N       = 16,
    /* Data width of the payload in bits. Lose efficacy if `DTYPE` is overwritten. @range: ">=1"*/
    parameter int unsigned DW      = 1,
    /*
    The `EXT_RR` option allows to override the internal round robin counter via the
    `rr_i` signal. `rr_i` must be a big-endian thermometer code signal, such as '1111_1000'
    which means the priority of idx is '3,4,5,6,7,0,1,2'.
    This can be useful in case multiple arbiters need to have
    rotating priorities that are operating in lock-step. If static priority arbitration
    is needed, just connect `rr_i` to '0.
    Set to 1'b1 to enable. @range: "{0,1}"
    */
    parameter bit          EXT_RR  = 1'b0,
    /*
    If `LEAKY` is set, the `req_o` will leak out whenever any `req_i` is valid,
    and the `gnt_o` will leak out whenever `gnt_i` is valid.
    Enabling `LEAKY` make the request no longer depends on grant,
    leads to a reduction of arbiter delay and area.
    Set to 1'b1 to enable. @range: "{0,1}"
    */
    parameter bit          LEAKY   = 1'b1,
    /*
    There are three basic methods for updating the round-robin pointer: </br>
    1. After a grant, increment the pointer. This method don't cares which request is, so depth is 0. </br>
    2. After a grant, move the pointer to the requester after the one which just received the grant.
      This method only cares which request is granted, so depth is 1. </br>
    3. After a grant, move the pointer to the first Active requester after the one which just received the grant.
      This method cares which request is granted and the next valid request, so depth is 2. </br>
    Change `DEPTH` to set the updating method. @range: "{0,1,2}"
    */
    parameter int          DEPTH   = 1,
    /* Data type of the payload, can be overwritten with custom type. 
    Only use of `DW`. @range: "logic [DW-1:0]" */
    parameter type         DTYPE   = logic [DW-1:0],
    /* Width of the arbitration priority signal and the arbitrated index. 
    (auto-gen, do **NOT** change)@range: "$clog2(N)+(N==1)" */
    parameter int unsigned AW      = $clog2(N)+(N==1)
)(
    /* Clock, positive edge triggered. */
    input logic                 clk_i,
    /* Asynchronous reset, active low. */
    input logic                 rst_ni,
    /* Clears the arbiter state. Only used if `EXT_RR` is `1'b0`. */
    input logic                 flush_i,
    /* External round-robin priority. Only used if `EXT_RR` is `1'b1.` */
    input logic [N-1:0]         rr_i,
    /* Input requests arbitration. */
    input logic [N-1:0]         req_i,
    /* Input request locks. */
    input logic [N-1:0]         lock_i,
    /* Input request is granted. */
    output logic [N-1:0]        gnt_o,
    /* Input data for arbitration. */
    input DTYPE [N-1:0]         data_i,
    /* Output request is valid. */
    output logic                req_o,
    /* Output request lock. */
    output logic                lock_o,
    /* Output data. */
    output DTYPE                data_o,
    /* Index from which input the data came from. */
    output logic [AW-1:0]       idx_o,
    /* Output request is granted. */
    input logic                 gnt_i
);

    // just pass through in this corner case
    if (N == unsigned'(1)) begin : gen_pass_through
        assign req_o    = req_i[0];
        assign gnt_o[0] = gnt_i;
        assign data_o   = data_i[0];
        assign idx_o    = '0;
        assign lock_o   = lock_i[0];
    // non-degenerate cases
    end else begin : gen_arbiter
        localparam int unsigned NumLevels = unsigned'($clog2(N));
        localparam type idx_t = logic [AW-1:0];

        /* lint_off */
        logic [N-1:0]               rr_q;
        logic [N-1:0]               req_d;
        logic [N-1:0]               req_mask;
        logic [N-1:0]               rr_d;
        logic [N-1:0]               gnt_d; // generated by tree
        idx_t                       gnt_idx_r; // used to lock the arbitration decision


        logic  lock_d, lock_q;

        assign lock_d     = lock_q ? lock_i[gnt_idx_r] : lock_o && req_o;
        assign req_d      = lock_q ? req_mask : req_i;

        always_ff @(posedge clk_i or negedge rst_ni) begin : p_lock_reg
            if (!rst_ni) begin
                lock_q <= '0;
            end else begin
                if (flush_i) begin
                    lock_q <= '0;
                end else begin
                    lock_q <= lock_d;
                end
            end
        end

        always_ff @(posedge clk_i or negedge rst_ni) begin
            if(~rst_ni) begin
                gnt_idx_r <= 'b0;
            end else begin
                if(~lock_q)begin
                    gnt_idx_r <= idx_o;
                end
            end
        end
        
        for (genvar i = 0; i < N; i++) begin : gen_mask
            assign req_mask[i] = (i == gnt_idx_r) ? req_i[i] : 1'b0;
        end


        if (EXT_RR) begin : gen_ext_rr
            assign rr_q       = rr_i;
        end else begin : gen_int_rr
            always_ff @(posedge clk_i or negedge rst_ni) begin : p_rr_regs
                if (!rst_ni) begin
                    rr_q   <= '0;
                end else begin
                    if (flush_i) begin
                        rr_q   <= '0;
                    end else begin
                        if(gnt_i && req_o && ~lock_q) begin
                            rr_q   <= rr_d;
                        end
                    end
                end
            end
        end

    
        /* verilator lint_off UNOPTFLAT */
        idx_t    [2**NumLevels-2:0] index_nodes; // used to propagate the indices
        DTYPE    [2**NumLevels-2:0] data_nodes;  // used to propagate the data
        logic    [2**NumLevels-2:0] gnt_nodes;   // used to propagate the grant to masters
        
        logic    [2**NumLevels-2:0] req_nodes;   // used to propagate the requests to slave
        logic    [2**NumLevels-2:0] lock_nodes;  // used to propagate the locks to slave
        logic    [2**NumLevels-2:0] mask_nodes;  // used to propagate the prior to lower level

        assign gnt_nodes[0] = gnt_i;
        
        if(DEPTH==0)begin // fair-less arbiter tree (depth:0)
            // rr_q holds the highest priority
            assign rr_d = ~rr_q[N-1] ? -2 : {rr_q[N-2:0],1'b0};
            for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
                for (genvar l = 0; l < 2**level; l++) begin : gen_level
                    // local select signal
                    logic sel;
                    // index calcs
                    localparam int unsigned Idx0 = 2**level-1+l;// current node
                    localparam int unsigned Idx1 = 2**(level+1)-1+l*2;// odd node from upper Level connected to Idx0
                    localparam int unsigned Idx2 = 2**(level+1)-1+l*2+1;// even node from upper Level connected to Idx0

                    if (unsigned'(level) == NumLevels-1) begin : gen_first_level

                        // odd-even tree fabric
                        if (unsigned'(l)*2 < N-1) begin
                            assign req_nodes[Idx0]        = req_d[l*2] | req_d[l*2+1];
                            assign sel                    = req_d[l*2+1]&~req_d[l*2] 
                                                          | req_d[l*2+1]&rr_q[l*2+1]&~rr_q[l*2] 
                                                          | ~req_d[l*2]&rr_q[l*2+1]&~rr_q[l*2];
                            assign index_nodes[Idx0]      = idx_t'(sel);
                            assign data_nodes[Idx0]       = (sel) ? data_i[l*2+1] : data_i[l*2];
                            assign lock_nodes[Idx0]       = (sel) ? lock_i[l*2+1] : lock_i[l*2];
                            assign mask_nodes[Idx0]       = (sel) ? rr_q[l*2+1] : rr_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0] & ~sel;
                            assign gnt_d[l*2+1]           = gnt_nodes[Idx0] & sel;
                        end
                        else if (unsigned'(l)*2 == N-1)begin
                            assign req_nodes[Idx0]        = req_d[l*2];
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = data_i[l*2];
                            assign lock_nodes[Idx0]       = lock_i[l*2];
                            assign mask_nodes[Idx0]       = rr_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0];
                        end else begin
                            assign req_nodes[Idx0]        = 1'b0;
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = DTYPE'('0);
                            assign lock_nodes[Idx0]       = 1'b0;
                        end

                    end else begin : gen_other_levels

                        // odd-even tree fabric
                        assign req_nodes[Idx0]        = req_nodes[Idx1] | req_nodes[Idx2];
                        assign sel                    = req_nodes[Idx2]&~req_nodes[Idx1] 
                                                      | req_nodes[Idx2]&mask_nodes[Idx2]&~mask_nodes[Idx1] 
                                                      | ~req_nodes[Idx1]&mask_nodes[Idx2]&~mask_nodes[Idx1];
                        assign index_nodes[Idx0]      = (sel) 
                                                      ? idx_t'({1'b1, index_nodes[Idx2][NumLevels-unsigned'(level)-2:0]}) 
                                                      : idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});
                        assign data_nodes[Idx0]       = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];
                        assign lock_nodes[Idx0]       = (sel) ? lock_nodes[Idx1+1] : lock_nodes[Idx1];
                        assign mask_nodes[Idx0]       = (sel) ? mask_nodes[Idx2] : mask_nodes[Idx1];
                        assign gnt_nodes[Idx1]        = gnt_nodes[Idx0] & ~sel;
                        assign gnt_nodes[Idx2]        = gnt_nodes[Idx0] & sel;
                    end
                end
            end

        end else if(DEPTH==1)begin // fair more arbiter tree (depth:1)

            logic    [2**NumLevels-2:0] rr_nodes;   // used to propagate the rr_d to rr_q

            assign rr_nodes[0] = 1'b0;

            // rr_d is the requester next to grantee
            for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
                for (genvar l = 0; l < 2**level; l++) begin : gen_level
                    // local select signal
                    logic sel;
                    // index calcs
                    localparam int unsigned Idx0 = 2**level-1+l;// current node
                    localparam int unsigned Idx1 = 2**(level+1)-1+l*2;// odd node from upper Level connected to Idx0
                    localparam int unsigned Idx2 = 2**(level+1)-1+l*2+1;// even node from upper Level connected to Idx0

                    if (unsigned'(level) == NumLevels-1) begin : gen_first_level

                        // odd-even tree fabric
                        if (unsigned'(l)*2 < N-1) begin
                            assign req_nodes[Idx0]        = req_d[l*2] | req_d[l*2+1];
                            assign sel                    = req_d[l*2+1]&~req_d[l*2] 
                                                          | req_d[l*2+1]&rr_q[l*2+1]&~rr_q[l*2] 
                                                          | ~req_d[l*2]&rr_q[l*2+1]&~rr_q[l*2];
                            assign index_nodes[Idx0]      = idx_t'(sel);
                            assign data_nodes[Idx0]       = (sel) ? data_i[l*2+1] : data_i[l*2];
                            assign lock_nodes[Idx0]       = (sel) ? lock_i[l*2+1] : lock_i[l*2];
                            assign mask_nodes[Idx0]       = (sel) ? rr_q[l*2+1] : rr_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0] & ~sel;
                            assign gnt_d[l*2+1]           = gnt_nodes[Idx0] & sel;
                            assign rr_d[l*2]              = rr_nodes[Idx0];
                            assign rr_d[l*2+1]            = rr_nodes[Idx0] | gnt_nodes[Idx0]&~sel;
                        end
                        else if (unsigned'(l)*2 == N-1)begin
                            assign req_nodes[Idx0]        = req_d[l*2];
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = data_i[l*2];
                            assign lock_nodes[Idx0]       = lock_i[l*2];
                            assign mask_nodes[Idx0]       = rr_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0];
                            assign rr_d[l*2]              = gnt_nodes[Idx0];
                        end else begin
                            assign req_nodes[Idx0]        = 1'b0;
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = DTYPE'('0);
                            assign lock_nodes[Idx0]       = 1'b0;
                            assign mask_nodes[Idx0]       = 1'b0;
                        end

                    end else begin : gen_other_levels

                        // odd-even tree fabric
                        assign req_nodes[Idx0]        = req_nodes[Idx1] | req_nodes[Idx2];
                        assign sel                    = req_nodes[Idx2]&~req_nodes[Idx1] 
                                                      | req_nodes[Idx2]&mask_nodes[Idx2]&~mask_nodes[Idx1] 
                                                      | ~req_nodes[Idx1]&mask_nodes[Idx2]&~mask_nodes[Idx1];
                        assign index_nodes[Idx0]      = (sel) 
                                                      ? idx_t'({1'b1, index_nodes[Idx2][NumLevels-unsigned'(level)-2:0]}) 
                                                      : idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});
                        assign data_nodes[Idx0]       = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];
                        assign lock_nodes[Idx0]       = (sel) ? lock_nodes[Idx1+1] : lock_nodes[Idx1];
                        assign mask_nodes[Idx0]       = (sel) ? mask_nodes[Idx2] : mask_nodes[Idx1];
                        assign gnt_nodes[Idx1]        = gnt_nodes[Idx0] & ~sel;
                        assign gnt_nodes[Idx2]        = gnt_nodes[Idx0] & sel;
                        assign rr_nodes[Idx1]         = rr_nodes[Idx0];
                        assign rr_nodes[Idx2]         = rr_nodes[Idx0] | gnt_nodes[Idx0]&~sel;
                    end
                end
            end
        end else begin // fair most arbiter tree (depth:2)

            // need sencond tree to find next valid request
            logic    [2**NumLevels-2:0] mask2_nodes;  // used to propagate the prior2 to lower level
            logic    [2**NumLevels-2:0] gnt2_nodes;  // used to propagate the mask to upper level
            logic    [2**NumLevels-2:0] rr_nodes;   // used to propagate the rr_d to rr_q
            logic    [N-1:0]            rr2_q;

            assign rr_nodes[0]   = 1'b0;
            assign gnt2_nodes[0] = gnt_i;
            assign rr2_q         = ~rr_q[N-1] ? -2 :{rr_q[N-2:0],1'b0};

            for (genvar level = 0; unsigned'(level) < NumLevels; level++) begin : gen_levels
                for (genvar l = 0; l < 2**level; l++) begin : gen_level
                    // local select signal
                    logic sel;
                    logic sel2;
                    // index calcs
                    localparam int unsigned Idx0 = 2**level-1+l;// current node
                    localparam int unsigned Idx1 = 2**(level+1)-1+l*2;// odd node from upper Level connected to Idx0
                    localparam int unsigned Idx2 = 2**(level+1)-1+l*2+1;// even node from upper Level connected to Idx0

                    if (unsigned'(level) == NumLevels-1) begin : gen_first_level

                        // odd-even tree fabric
                        if (unsigned'(l)*2 < N-1) begin
                            assign req_nodes[Idx0]        = req_d[l*2] | req_d[l*2+1];
                            assign sel                    = req_d[l*2+1]&~req_d[l*2] 
                                                          | req_d[l*2+1]&rr_q[l*2+1]&~rr_q[l*2] 
                                                          | ~req_d[l*2]&rr_q[l*2+1]&~rr_q[l*2];
                            assign sel2                   =  req_d[l*2+1]&~req_d[l*2] 
                                                          | req_d[l*2+1]&rr2_q[l*2+1]&~rr2_q[l*2] 
                                                          | ~req_d[l*2]&rr2_q[l*2+1]&~rr2_q[l*2];
                            assign index_nodes[Idx0]      = idx_t'(sel);
                            assign data_nodes[Idx0]       = (sel) ? data_i[l*2+1] : data_i[l*2];
                            assign lock_nodes[Idx0]       = (sel) ? lock_i[l*2+1] : lock_i[l*2];
                            assign mask_nodes[Idx0]       = (sel) ? rr_q[l*2+1] : rr_q[l*2];
                            assign mask2_nodes[Idx0]      = (sel2) ? rr2_q[l*2+1] : rr2_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0] & ~sel;
                            assign gnt_d[l*2+1]           = gnt_nodes[Idx0] & sel;
                            assign rr_d[l*2]              = rr_nodes[Idx0] | gnt2_nodes[Idx0]&~sel2;
                            assign rr_d[l*2+1]            = rr_nodes[Idx0] | gnt2_nodes[Idx0];
                        end
                        else if (unsigned'(l)*2 == N-1)begin
                            assign req_nodes[Idx0]        = req_d[l*2];
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = data_i[l*2];
                            assign lock_nodes[Idx0]       = lock_i[l*2];
                            assign mask_nodes[Idx0]       = rr_q[l*2];
                            assign mask2_nodes[Idx0]      = rr2_q[l*2];
                            assign gnt_d[l*2]             = gnt_nodes[Idx0];
                            assign rr_d[l*2]              = gnt2_nodes[Idx0];
                        end else begin
                            assign req_nodes[Idx0]        = 1'b0;
                            assign index_nodes[Idx0]      = idx_t'('0);// always zero in this case
                            assign data_nodes[Idx0]       = DTYPE'('0);
                            assign lock_nodes[Idx0]       = 1'b0;
                            assign mask_nodes[Idx0]       = 1'b0;
                            assign mask2_nodes[Idx0]      = 1'b0;
                        end

                    end else begin : gen_other_levels

                        // odd-even tree fabric
                        assign req_nodes[Idx0]        = req_nodes[Idx1] | req_nodes[Idx2];
                        assign sel                    = req_nodes[Idx2]&~req_nodes[Idx1] 
                                                      | req_nodes[Idx2]&mask_nodes[Idx2]&~mask_nodes[Idx1] 
                                                      | ~req_nodes[Idx1]&mask_nodes[Idx2]&~mask_nodes[Idx1];
                        assign sel2                   = req_nodes[Idx2]&~req_nodes[Idx1] 
                                                      | req_nodes[Idx2]&mask2_nodes[Idx2]&~mask2_nodes[Idx1] 
                                                      | ~req_nodes[Idx1]&mask2_nodes[Idx2]&~mask2_nodes[Idx1];
                        assign index_nodes[Idx0]      = (sel) 
                                                      ? idx_t'({1'b1, index_nodes[Idx2][NumLevels-unsigned'(level)-2:0]}) 
                                                      : idx_t'({1'b0, index_nodes[Idx1][NumLevels-unsigned'(level)-2:0]});
                        assign data_nodes[Idx0]       = (sel) ? data_nodes[Idx1+1] : data_nodes[Idx1];
                        assign lock_nodes[Idx0]       = (sel) ? lock_nodes[Idx1+1] : lock_nodes[Idx1];
                        assign mask_nodes[Idx0]       = (sel) ? mask_nodes[Idx2] : mask_nodes[Idx1];
                        assign mask2_nodes[Idx0]      = (sel2) ? mask2_nodes[Idx2] : mask2_nodes[Idx1];
                        assign gnt_nodes[Idx1]        = gnt_nodes[Idx0] & ~sel;
                        assign gnt_nodes[Idx2]        = gnt_nodes[Idx0] & sel;
                        assign gnt2_nodes[Idx1]       = gnt2_nodes[Idx0] & ~sel2;
                        assign gnt2_nodes[Idx2]       = gnt2_nodes[Idx0] & sel2;
                        assign rr_nodes[Idx1]         = rr_nodes[Idx0];
                        assign rr_nodes[Idx2]         = rr_nodes[Idx0] | gnt2_nodes[Idx0]&~sel2;
                    end
                end
            end
        end
        

        if(LEAKY) begin
            assign gnt_o    = gnt_d;
        end else begin
            assign gnt_o    = gnt_d & req_i;
        end

        assign req_o        = req_nodes[0];
        assign data_o       = data_nodes[0];
        assign idx_o        = index_nodes[0];
        assign lock_o       = lock_nodes[0];

    end
endmodule