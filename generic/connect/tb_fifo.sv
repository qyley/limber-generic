`timescale 1ns / 1ps
`define XSIM
module tb_fifo();
    parameter T = 10;

    reg clk,rst;
    reg [15:0] data_i;
    reg flush_i,wen_i,ren_i;

    gnrc_fifo #(
        .DW(16),
        .DP(13),
        .BYPASS(0)
    ) inst_gnrc_fifo (
        .clk_i   (clk),
        .rst_ni  (rst),
        .flush_i (flush_i),
        .data_i  (data_i),
        .wen_i   (wen_i),
        .ren_i   (ren_i)
    );





    initial begin
        clk = 0;
        rst = 0;
        data_i = 0;
        flush_i = 0;
        wen_i = 0;
        ren_i = 0;
        #20;
        rst = 1;
        #10;
        wen_i = 1;
        #500;
        ren_i = 1;
        #500;
        wen_i = 0;
        #500;
        wen_i = 1;
        #500;
        flush_i = 1;
        #100;
        flush_i = 0;
        #40;
        ren_i = 0;
        #100;
        wen_i = 0;
        #100;
        ren_i = 1;
        #500;
        $finish;

    end

    always #(T/2) clk = ~clk;
    always@(posedge clk) if(wen_i&~inst_gnrc_fifo.full_o) data_i <= data_i + 1;

endmodule