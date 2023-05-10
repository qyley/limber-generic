/*----------------------------------------------------------------
|
| Synchronous Normal FIFO
|
| Vivado can decide to implement this FIFO by DistRAM or BlockRAM **automatically**
  according to its scale of parameter DW and DP

-----------------------------------------------------------------*/
`include "gnrc_ff.svh"
module gnrc_fifo #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* FIFO depth @range: ">=2" */
    parameter DP = 512,
    /* 1 to enable First Word Fall Through FIFO, 0 for Standard FIFO. @range: "{0,1}" */
    parameter bit FWFT = 1,
    /* Bypass `data_i` to `data_o` when fifo is empty. **Only use in FWFT mode** .
    If `BYPASS` activated, a combinational path exists between output and input.
    In the case of simultaneously read and write when FIFO is empty,
    data_o can derived directly from data_in.
    This feature is useful under some situations.
    However if you needn't this, set `BYPASS` = 0. @range: "{0,1}" */
    parameter bit BYPASS = 0,
    /* data counter bit width (auto-gen, do **NOT** change) @range: "$clog2(DP+1)" */
    parameter CW = $clog2(DP+1)
) (
    /* Clock, positive edge triggered. */
    input logic clk_i,
    /* Asynchronous reset, active low. */
    input logic rst_ni,
    /* Clears all data in FIFO.
    flush can only clear registered data, **NO** effect on combinational path.*/
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
    output logic [DW-1:0] data_o,
    /* number of data in FIFO ,
    it may be **NOT** accurate in `FWFT` mode*/
    output logic [CW-1:0] data_cnt_o
);

    localparam AW = $clog2(DP);

    logic               mem_wen, mem_ren;
    logic   [DW-1:0]    mem_wdata, mem_rdata;
    logic   [AW-1:0]    mem_waddr, mem_raddr;

    gnrc_mem2fifo #(
        .DW(DW),
        .DP(DP),
        .FWFT(FWFT),
        .DELAY(1),
        .BYPASS(BYPASS)
    ) inst_gnrc_mem2fifo (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .fifo_flush_i (flush_i),
        .fifo_data_i  (data_i),
        .fifo_wen_i   (wen_i),
        .fifo_ren_i   (ren_i),
        .fifo_full_o  (full_o),
        .fifo_empty_o (empty_o),
        .fifo_data_o  (data_o),
        .fifo_cnt_o   (data_cnt_o),
        .mem_wen_o    (mem_wen),
        .mem_waddr_o  (mem_waddr),
        .mem_wdata_o  (mem_wdata),
        .mem_ren_o    (mem_ren),
        .mem_raddr_o  (mem_raddr),
        .mem_rdata_i  (mem_rdata)
    );

    gnrc_simple_dpram #(
        .DW(DW),
        .DP(DP),
        .DELAY(1)
    ) inst_gnrc_simple_dpram (
        .wclk_i  (clk_i),
        .wdata_i (mem_wdata),
        .wen_i   (1'b1),
        .we_i    (mem_wen),
        .waddr_i (mem_waddr),
        .rclk_i  (clk_i),
        .ren_i   (mem_ren),
        .raddr_i (mem_raddr),
        .rdata_o (mem_rdata)
    );


endmodule
