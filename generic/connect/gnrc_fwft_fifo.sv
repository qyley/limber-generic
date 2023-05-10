/*----------------------------------------------------------------
|
| Synchronous First-Word-Fall-Through FIFO
|
| This module need zero delay RAM(i.e read data can output instantly).
| Suitable for implementation of shallow depth FIFO in FPGA.
| If you need a deep depth FIFO, a `gnrc_fifo` or `gnrc_mem2fifo` is more porper.

-----------------------------------------------------------------*/
`include "gnrc_ff.svh"
module gnrc_fwft_fifo #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* FIFO depth @range: ">=1" */
    parameter DP = 8,
    /* Bypass `data_i` to `data_o` when fifo is empty.
    If `BYPASS` activated, a combinational path exists between output and input.
    In the case of simultaneously read and write when FIFO is empty,
    data_o can derived directly from data_in.
    This feature is useful under some situations.
    However if you needn't this, set `BYPASS` = 0. @range: "{0,1}" */
    parameter bit BYPASS = 0
) (
    /* Clock, positive edge triggered. */
    input logic clk_i,
    /* Asynchronous reset, active low. */
    input logic rst_ni,
    /* Clears all data in FIFO.
    flush can only clear registered data, **NO** effect on combinational path. */
    input logic flush_i,
    /* data input */
    input logic [DW-1:0] data_i,
    /* write enable (push) */
    input logic wen_i,
    /* read enable (pop) */
    input logic ren_i,
    /* FIFO full */
    output logic full_o,
    /* FIFO empty */
    output logic empty_o,
    /* data output */
    output logic [DW-1:0] data_o
);

    if(DP==1) begin
        // Degenerate to backwawrd-registered slice
        logic ready_o;
        logic valid_o;

        gnrc_slice #(
            .DW(DW),
            .FORWARD_Q(BYPASS==0),
            .BACKWARD_Q(BYPASS==1)
        ) inst_gnrc_slice_1(
            .clk_i   (clk_i),
            .rst_ni  (rst_ni),
            .flush_i (flush_i),
            .valid_i (wen_i),
            .data_i  (data_i),
            .ready_o (ready_o),
            .valid_o (valid_o),
            .data_o  (data_o),
            .ready_i (ren_i)
        );

        assign full_o = ~ready_o;
        assign empty_o = ~valid_o;

    end
    else if(DP==2) begin
        // Degenerate to full-registered slice
        logic valid_i;
        logic ready_o;
        logic valid_o;
        logic [DW-1:0] data_q;

        gnrc_slice #(
            .DW(DW),
            .FORWARD_Q(1),
            .BACKWARD_Q(1)
        ) inst_gnrc_slice_2 (
            .clk_i   (clk_i),
            .rst_ni  (rst_ni),
            .flush_i (flush_i),
            .valid_i (valid_i),
            .data_i  (data_i),
            .ready_o (ready_o),
            .valid_o (valid_o),
            .data_o  (data_q),
            .ready_i (ren_i)
        );

        if(BYPASS) begin
            assign valid_i = wen_i & ~(~valid_o&ren_i);
            assign full_o = ~ready_o;
            assign empty_o = ~valid_o & ~wen_i;
            assign data_o = valid_o ? data_q : data_i;
        end
        else begin
            assign valid_i = wen_i;
            assign full_o = ~ready_o;
            assign empty_o = ~valid_o;
            assign data_o = data_q;
        end
        

    end
    else begin
        
        localparam AW = $clog2(DP);

        logic   [AW-1:0]    ram_waddr_d, ram_waddr_q;
        logic   [AW-1:0]    ram_raddr_d, ram_raddr_q;
        logic               ram_waddr_wen;
        logic               ram_raddr_wen;
        logic   [DW-1:0]    ram_wdata;
        logic   [DW-1:0]    ram_rdata;
        logic               ram_wen;
        logic               ram_ren;

        logic               ram_empty, ram_full;

        logic   [AW:0]      ram_cnt_q;

        always_ff @(posedge clk_i or negedge rst_ni) begin
            if(~rst_ni) begin
                ram_cnt_q <= 'b0;
            end else begin
                if(flush_i) begin
                    ram_cnt_q <= 'b0;
                end else begin
                    if(ram_wen&~ram_ren)begin
                        ram_cnt_q <= ram_cnt_q+1;
                    end
                    if(~ram_wen&ram_ren)begin
                        ram_cnt_q <= ram_cnt_q-1;
                    end
                end
            end
        end

        assign ram_empty = ram_cnt_q==0;
        assign ram_full = ram_cnt_q==DP;

        assign ram_wdata     = data_i;
        assign ram_waddr_d   = (ram_waddr_q==DP-1) ? 'b0 : ram_waddr_q + 1;
        assign ram_raddr_d   = (ram_raddr_q==DP-1) ? 'b0 : ram_raddr_q + 1;
        assign ram_wen       = wen_i & ~full_o;
        assign ram_ren       = ren_i & ~empty_o;

        `gnrc_fflarnc(clk_i, rst_ni, ram_waddr_wen, flush_i, ram_waddr_d, ram_waddr_q)
        `gnrc_fflarnc(clk_i, rst_ni, ram_raddr_wen, flush_i, ram_raddr_d, ram_raddr_q)

        gnrc_dist_dpram #(
            .DW(DW),
            .DP(DP),
            .IBUF(0),
            .OBUF(0)
        ) inst_gnrc_dist_dpram (
            .clk_i   (clk_i),
            .din_i   (ram_wdata),
            .we_i    (ram_waddr_wen),
            .addr_i  (ram_waddr_q),
            .addrb_i (ram_raddr_q),
            .dout_o  (),
            .doutb_o (ram_rdata)
        );

        if(BYPASS)begin
            assign ram_waddr_wen = ram_wen & ~(ram_empty&ren_i);
            assign ram_raddr_wen = ram_ren & ~(ram_empty&wen_i);
            assign empty_o = ram_empty & ~wen_i;
            assign full_o = ram_full;
            assign data_o = ram_empty ? data_i : ram_rdata;
        end
        else begin
            assign ram_waddr_wen = ram_wen;
            assign ram_raddr_wen = ram_ren;
            assign empty_o = ram_empty;
            assign full_o = ram_full;
            assign data_o = ram_rdata;
        end
        
    end


endmodule