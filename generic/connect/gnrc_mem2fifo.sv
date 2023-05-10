/*----------------------------------------------------------------
|
| Convert a memory interface to FIFO interface
|

Notation:
 This module Need a dual-port memory 
 (like a simple dual-port RAM) connecting from outside

-----------------------------------------------------------------*/
`include "gnrc_ff.svh"
module gnrc_mem2fifo #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* FIFO depth @range: ">=2" */
    parameter DP = 512,
    /* 1 to enable First Word Fall Through FIFO, 0 for Standard FIFO. @range: "{0,1}" */
    parameter bit FWFT = 1,
    /* latency of read of memory which equal to the depth of FWFT buffer, useless if `FWFT` is 0 @range: ">=0" */
    parameter DELAY = 1,
    /* Bypass `data_i` to `data_o` when fifo is empty. **Only use in FWFT mode** .
    If `BYPASS` activated, a combinational path exists between output and input.
    In the case of simultaneously read and write when FIFO is empty,
    data_o can derived directly from data_in.
    This feature is useful under some situations.
    However if you needn't this, set `BYPASS` = 0. @range: "{0,1}" */
    parameter bit BYPASS = 0,
    /* Address bit width (auto-gen, do **NOT** change) @range: "$clog2(DP)" */
    parameter AW = $clog2(DP),
    /* data counter bit width (auto-gen, do **NOT** change) @range: "$clog2(DP+1)" */
    parameter CW = $clog2(DP+1)
) (
    /* Clock, positive edge triggered. Must synchronous with memory's clock*/
    input logic clk_i,
    /* Asynchronous reset, active low. */
    input logic rst_ni,
    /* Clears all data in FIFO.
    flush can only clear registered data, **NO** effect on combinational path. */
    input logic fifo_flush_i,
    /* data input */
    input logic [DW-1:0] fifo_data_i,
    /* write enable (push) */
    input logic fifo_wen_i,
    /* read enable (pop) */
    input logic fifo_ren_i,
    /* FIFO full */
    output logic fifo_full_o,
    /* FIFO empty */
    output logic fifo_empty_o,
    /* data output */
    output logic [DW-1:0] fifo_data_o,
    /* number of data in FIFO ,
    it may be **NOT** accurate in `FWFT` mode,
    and the scale of inaccuracy depends on the `DELAY` of the memory*/
    output logic [CW-1:0] fifo_cnt_o,

    /* memory write enable */
    output mem_wen_o,
    /* memory write address */
    output [AW-1:0] mem_waddr_o,
    /* memory write data */
    output [DW-1:0] mem_wdata_o,

    /* memory read enable */
    output mem_ren_o,
    /* memory read address */
    output [AW-1:0] mem_raddr_o,
    /* memory read data */
    input [DW-1:0] mem_rdata_i
);

    logic   [AW-1:0]    mem_waddr_d, mem_waddr_q;
    logic   [AW-1:0]    mem_raddr_d, mem_raddr_q;
    logic               mem_waddr_wen;
    logic               mem_raddr_wen;

    logic   [DW-1:0]    mem_wdata;
    logic               mem_wen;
    logic               mem_ren;

    logic               mem_empty, mem_full;

    logic   [AW:0]      mem_cnt_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            mem_cnt_q <= 'b0;
        end else begin
            if(fifo_flush_i) begin
                mem_cnt_q <= 'b0;
            end else begin
                if(mem_wen&~mem_ren)begin
                    mem_cnt_q <= mem_cnt_q+1;
                end
                if(~mem_wen&mem_ren)begin
                    mem_cnt_q <= mem_cnt_q-1;
                end
            end
        end
    end

    assign mem_empty = mem_cnt_q==0;
    assign mem_full = mem_cnt_q==DP;
    

    assign mem_wdata     = fifo_data_i;
    assign mem_waddr_d   = (mem_waddr_q==DP-1) ? 'b0 : mem_waddr_q + 1;
    assign mem_raddr_d   = (mem_raddr_q==DP-1) ? 'b0 : mem_raddr_q + 1;

    `gnrc_fflarnc(clk_i, rst_ni, mem_waddr_wen, fifo_flush_i, mem_waddr_d, mem_waddr_q)
    `gnrc_fflarnc(clk_i, rst_ni, mem_raddr_wen, fifo_flush_i, mem_raddr_d, mem_raddr_q)


    if(FWFT&&(DELAY>0)) begin

        logic skid_wen;
        logic [DW-1:0] skid_wdata;
        logic skid_ren;
        logic skid_full;
        logic mem_rdata_valid;

        // if skid buffer bypass is disable, the skid buffer need one more entry for its delay
        localparam SKID_DEPTH = DELAY + (BYPASS==0);
        localparam SKID_CW = $clog2(SKID_DEPTH+1);
        logic [SKID_CW-1:0] skid_cnt, outstanding_cnt;
        logic outstanding_idle;

        // skid counter record skid buffer have requested how many data from memory
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if(~rst_ni) begin
                skid_cnt <= 'b0;
            end else begin
                if(fifo_flush_i)begin
                    skid_cnt <= 'b0;
                end else begin
                    if(skid_wen&~(fifo_ren_i&~fifo_empty_o))begin
                        skid_cnt <= skid_cnt + 1;
                    end
                    if(~skid_wen&(fifo_ren_i&~fifo_empty_o))begin
                        skid_cnt <= skid_cnt - 1;
                    end
                end
            end
        end

        // outstanding counter record how many requests have not been write back to skid buffer yet
        always_ff @(posedge clk_i or negedge rst_ni) begin
            if(~rst_ni) begin
                outstanding_cnt <= 'b0;
            end else begin
                if(fifo_flush_i)begin
                    outstanding_cnt <= 'b0;
                end else begin
                    if(mem_ren&~mem_rdata_valid)begin
                        outstanding_cnt <= outstanding_cnt + 1;
                    end
                    if(~mem_ren&mem_rdata_valid)begin
                        outstanding_cnt <= outstanding_cnt - 1;
                    end
                end
            end
        end

        assign outstanding_idle = outstanding_cnt==0;
        assign skid_full = skid_cnt==SKID_DEPTH;

        gnrc_shift_reg #(
            .DEPTH(DELAY),
            .DTYPE(logic)
        ) inst_gnrc_shift_reg (
            .clk_i  (clk_i),
            .rst_ni (rst_ni),
            .flush_i(fifo_flush_i),
            .d_i    (mem_ren),
            .d_o    (mem_rdata_valid)
        );

        gnrc_fwft_fifo #(
            .DW(DW),
            .DP(SKID_DEPTH),
            .BYPASS(BYPASS)
        ) u_skid_buffer (
            .clk_i   (clk_i),
            .rst_ni  (rst_ni),
            .flush_i (fifo_flush_i),
            .data_i  (skid_wdata),
            .wen_i   (skid_wen),
            .ren_i   (skid_ren),
            .full_o  (/* unused */),
            .empty_o (fifo_empty_o),
            .data_o  (fifo_data_o)
        );


        // write fifo_data_i to skid:
        // 1. wen_i and mem_empty and skid_buffer not full and no outstanding transaction is pending.
        // write mem_rdata_i to skid:
        // 2. mem_rdata_valid.
        assign skid_wen      = (fifo_wen_i&mem_empty&~skid_full&outstanding_idle) | mem_rdata_valid;
        assign skid_ren      = fifo_ren_i;
        assign skid_wdata    = mem_rdata_valid ? mem_rdata_i : fifo_data_i;
        
        // write fifo_data_i to mem:
        // 1. wen_i and fifo not full and not write to skid buffer
        assign mem_wen       = fifo_wen_i & ~fifo_full_o & ~(mem_empty&~skid_full&outstanding_idle);
        assign mem_waddr_wen = mem_wen;
        assign mem_ren       = fifo_ren_i & ~mem_empty;
        assign mem_raddr_wen = mem_ren;

        assign mem_wen_o     = mem_wen;
        assign mem_wdata_o   = fifo_data_i;
        assign mem_waddr_o   = mem_waddr_q;
        assign mem_ren_o     = mem_ren;
        assign mem_raddr_o   = mem_raddr_q;
        assign fifo_full_o   = mem_full;
        assign fifo_cnt_o    = mem_cnt_q;

    end else begin

        if(FWFT&BYPASS) begin
            assign mem_wen       = fifo_wen_i & ~fifo_full_o;
            assign mem_waddr_wen = mem_wen & ~(mem_empty&fifo_ren_i);
            assign mem_ren       = fifo_ren_i & ~fifo_empty_o;
            assign mem_raddr_wen = mem_ren & ~(mem_empty&fifo_wen_i);

            assign mem_wen_o     = mem_wen;
            assign mem_wdata_o   = fifo_data_i;
            assign mem_waddr_o   = mem_waddr_q;
            assign mem_ren_o     = mem_ren;
            assign mem_raddr_o   = mem_raddr_q;
            assign fifo_data_o   = mem_empty ? fifo_data_i : mem_rdata_i;
            assign fifo_empty_o  = mem_empty & ~fifo_wen_i;
            assign fifo_full_o   = mem_full;
            assign fifo_cnt_o    = mem_cnt_q;
        end
        else begin
            assign mem_wen       = fifo_wen_i & ~fifo_full_o;
            assign mem_waddr_wen = mem_wen;
            assign mem_ren       = fifo_ren_i & ~fifo_empty_o;
            assign mem_raddr_wen = mem_ren;

            assign mem_wen_o     = mem_wen;
            assign mem_wdata_o   = fifo_data_i;
            assign mem_waddr_o   = mem_waddr_q;
            assign mem_ren_o     = mem_ren;
            assign mem_raddr_o   = mem_raddr_q;
            assign fifo_data_o   = mem_rdata_i;
            assign fifo_empty_o  = mem_empty;
            assign fifo_full_o   = mem_full;
            assign fifo_cnt_o    = mem_cnt_q;
        end
    end

endmodule