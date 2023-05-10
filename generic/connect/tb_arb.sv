`timescale 1ns / 1ps
`define XSIM
module tb_arb();
    parameter T = 10;

    reg clk,rst;
    reg [7:0] req,lock;

    gnrc_arbiter #(
        .N(8),
        .DW(8),
        .EXT_RR(0),
        .LEAKY(0),
        .DEPTH(2)
    ) inst_gnrc_arbiter (
        .clk_i   (clk),
        .rst_ni  (rst),
        .flush_i (0),
        .rr_i    (0),
        .req_i   (req),
        .lock_i  (lock),
        .gnt_o   (),
        .data_i  (64'h0807060504030201),
        .req_o   (),
        .data_o  (),
        .gnt_i   (1)
    );


   rr_arb_tree #(
       .NumIn(8),
       .DataWidth(8),
       .AxiVldRdy(1)
   ) inst_rr_arb_tree (
       .clk_i   (clk),
       .rst_ni  (rst),
       .flush_i (0),
       .rr_i    (0),
       .req_i   (req),
       .gnt_o   (),
       .data_i  (64'h0807060504030201),
       .req_o   (),
       .gnt_i   (1),
       .data_o  (),
       .idx_o   ()
   );



    initial begin
        clk = 0;
        rst = 0;
        req = 0;
        lock = 0;
        #20;
        rst = 1;
        #10;
        req = 8'h01;
        lock = 8'b0000;
        #10;
        req = 8'h08;
        #10;
        req = 8'h30;
        #10;
        req = 8'h05;
        #50;
        lock = 8'b1000;
        req = 8'h03;
        #50;
        lock = 8'b0001;
        req = 8'hff;
        #50;
        lock = 8'b0100;
        #100;
        lock = 8'b0000;
        #400;
        $finish;

    end

    always #(T/2) clk = ~clk;

endmodule