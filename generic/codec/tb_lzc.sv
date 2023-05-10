`timescale 1ns / 1ps
module tb_lzc();
    parameter T = 10;
    parameter N = 13;

    logic clk;
    logic empty_o;
    logic[N-1:0] in_i;
    logic[$clog2(N)-1:0] cnt_o, bin_o2, bin_o3;
    logic[$clog2(N)-1:0] gray_o, bin_o;
    logic[2**$clog2(N)-1:0] onehot_o;
    logic[2**$clog2(N)-2:0] therm_o;

    gnrc_lzc_bin #(
        .WIDTH(N),
        .MODE(0)
    ) inst_gnrc_lzc (
        .in_i    (in_i),
        .cnt_o   (cnt_o),
        .empty_o (empty_o)
    );


    gnrc_bin2gray #(.N($clog2(N))) inst_gnrc_bin2gray (.bin_i(cnt_o), .gray_o(gray_o));

    gnrc_gray2bin #(.N($clog2(N))) inst_gnrc_gray2bin (.gray_i(gray_o), .bin_o(bin_o));

    gnrc_bin2onehot #(.N($clog2(N))) inst_gnrc_bin2onehot (.bin_i(bin_o), .onehot_o(onehot_o));

    gnrc_onehot2bin #(.N(N)) inst_gnrc_onehot2bin (.onehot_i(onehot_o[N-1:0]), .bin_o(bin_o2));

    gnrc_bin2therm #(.N($clog2(N))) inst_gnrc_bin2therm (.bin_i(bin_o2), .therm_o(therm_o));

    gnrc_therm2bin #(.N(N-1)) inst_gnrc_therm2bin (.therm_i(therm_o[N-2:0]), .bin_o(bin_o3));



    initial begin
        clk = 0;
        in_i = 0;
        #(4*T);
        in_i = 16'h0314;
        #(4*T);
        in_i = 16'h0500;
        #(4*T);
        in_i = 16'h1000;
        #(4*T);
        in_i = 16'hffff;
        #(4*T);
        $finish;

    end

    always #(T/2) clk = ~clk;

endmodule