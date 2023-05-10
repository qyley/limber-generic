`timescale 1ns / 1ps
`define XSIM
module tb_slice();
    parameter T = 10;

    reg clk,rst;
    reg [15:0] data_i;
    reg flush_i,valid_i,ready_i;

    gnrc_slice #(
        .DW(16),
        .FORWARD_Q(0),
        .BACKWARD_Q(1)
    ) inst_gnrc_slice (
        .clk_i   (clk),
        .rst_ni  (rst),
        .flush_i (flush_i),
        .valid_i (valid_i),
        .data_i  (data_i),
        .ready_o (),
        .valid_o (),
        .data_o  (),
        .ready_i (ready_i)
    );




    initial begin
        clk = 0;
        rst = 0;
        data_i = 0;
        flush_i = 0;
        valid_i = 0;
        ready_i = 0;
        #20;
        rst = 1;
        #10;
        valid_i = 1;
        #40;
        ready_i = 1;
        #50;
        valid_i = 0;
        #50;
        valid_i = 1;
        #50;
        flush_i = 1;
        #100;
        flush_i = 0;
        #40;
        ready_i = 0;
        #100;
        valid_i = 0;
        #100;
        ready_i = 1;
        #500;
        $finish;

    end

    always #(T/2) clk = ~clk;
    always@(posedge clk) if(valid_i&inst_gnrc_slice.ready_o) data_i <= data_i + 1;

endmodule