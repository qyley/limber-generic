`timescale 1ns / 1ps
module tb_ram();
    parameter T = 10;
    parameter N = 32;

    logic clk;
    logic [32-1:0] da_i, db_i;
    logic [10-1:0] addra_i, addrb_i;
    logic [4-1:0] wea_i,web_i;
    logic [32-1:0] qa_o,qb_o;

    gnrc_true_dpram #(
        .DW(32),
        .DP(1024),
        .DELAY(1),
        .OP_MODE(1),
        .BYTE_WRITE  (0),
        .INIT_BY_ZERO(1),
        .INIT_BY_FILE("C:/Users/QyLey/limber-docs/source/generic/generic/hexdata.txt")
    ) inst_gnrc_true_dpram (
        .clka_i  (clk),
        .dina_i  (da_i),
        .ena_i   (1'b1),
        .wea_i   (wea_i),
        .addra_i (addra_i),
        .douta_o (qa_o),
        .clkb_i  (clk),
        .dinb_i  (db_i),
        .enb_i   (1'b1),
        .web_i   (web_i),
        .addrb_i (addrb_i),
        .doutb_o (qb_o)
    );
    
    blk_mem_gen_0 u_bram0(
        .addra(addra_i),
        .clka(clk),
        .dina(da_i),
        .douta(),
        .ena(1'b1),
        .wea(wea_i),
        .addrb(addrb_i),
        .clkb(clk),
        .dinb(db_i),
        .doutb(),
        .enb(1'b1),
        .web(web_i)
    );


    initial begin
        clk = 0;
        da_i = 0;
        db_i = 0;
        addra_i = 0;
        addrb_i = 0;
        wea_i = 0;
        web_i = 0;
        #(4*T);
        addra_i = 2;
        da_i = 32'h111111f2;
        wea_i = 4'hf;
        addrb_i = 2;
        #(T);
        addra_i = 3;
        da_i = 3;
        wea_i = 1;
        #(T);
        addra_i = 2;
        da_i = 32'h88888888;
        wea_i = 1;
        #(T);
        addra_i = 5;
        da_i = 5;
        wea_i = 1;
        #(T);
        addra_i = 6;
        da_i = 6;
        wea_i = 1;
        addrb_i = 6;
        db_i = 66;
        web_i = 1;
        #(T);
        addra_i = 6;
        da_i = 0;
        wea_i = 0;
        addrb_i = 6;
        db_i = 0;
        wea_i = 0;
        #(4*T);
        $finish;

    end

    always #(T/2) clk = ~clk;

endmodule