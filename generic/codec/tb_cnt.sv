`timescale 1ns / 1ps
module tb_cnt();
    parameter T = 10;

    logic clk, rstn;
    logic mode_i, ld_i, clr_i, en_i, down_i;
    logic [15:0] bmax_i, binc_i;

    gnrc_fractional_counter #(
        .N(16)
    ) u_dut (
        .clk_i      (clk),
        .arstn_i    (rstn),
        .mode_i     (mode_i),
        .down_i     (down_i),
        .ld_i       (ld_i),
        .max_i      (bmax_i),
        .inc_i      (binc_i),
        .en_i       (en_i),
        .clr_i      (clr_i),
        .cnt_o      (),
        .overflow_o ()
    );



    initial begin
        clk = 0;
        rstn = 0;
        mode_i = 0;
        ld_i = 0;
        down_i = 0;
        bmax_i = 0;
        binc_i = 0;
        en_i = 0;
        clr_i = 0;
        #(4*T);
        rstn = 'b1;
        ld_i = 'b1;
        bmax_i = 26;
        binc_i = 3;
        en_i = 1;
        #(4*T);
        ld_i = 'b0;
        @(u_dut.overflow_o)
        #(4*T);
        clr_i = 1;
        down_i = 1;
        #(4*T);
        clr_i = 0;
        #(4*T);
        en_i = 0;
        #(4*T);
        clr_i = 0;
        #(4*T);
        en_i = 1;
        #(4*T);
        ld_i = 'b1;
        bmax_i = 16;
        binc_i = 5;
        #(4*T);
        ld_i = 'b0;
        #(4*T);
        mode_i = 1;
        #(400*T);
        $finish;

    end

    always #(T/2) clk = ~clk;

endmodule