`timescale 1ns / 1ps
`define XSIM
module tb_bus();
    parameter T = 10;

    localparam N_IN = 3;
    localparam N_OUT = 4;
    localparam DW = 8;
    localparam type DTYPE = logic [DW-1:0];
    localparam type DEST_T = logic [$clog2(N_OUT)-1:0];

    reg clk,rst,flush;
    
    DTYPE [N_IN-1:0] data_i;
    logic [N_IN-1:0] valid_i;
    logic [N_IN-1:0] last_i;
    DEST_T [N_IN-1:0] dest_i;
    logic [N_IN-1:0] ready_o;

    logic [N_OUT-1:0] ready_i;

    gnrc_stream_cross_bar #(
        .N_IN(N_IN),
        .N_OUT(N_OUT),
        .DTYPE(DTYPE),
        .ARB_MODE(3),
        .OBUF    (1)
    ) u_dut (
        .clk_i   (clk),
        .rst_ni  (rst),
        .flush_i (flush),
        .data_i  (data_i),
        .valid_i (valid_i),
        .last_i  (last_i),
        .dest_i  (dest_i),
        .ready_o (ready_o),
        .data_o  (),
        .valid_o (),
        .last_o  (),
        .ready_i (ready_i)
    );

    class manager;

        task manager_send(input int src, input int dst, input int len);
            int i;
            i = 0;
            while(i<len)begin
                data_i[src] = i+1;
                valid_i[src] = 1;
                last_i[src] = i==len-1;
                dest_i[src] = dst;
                while(~ready_o[src]) #1;
                i=i+1;
                #T;
            end
            valid_i[src] = 0;
        endtask

    endclass

    class subordinate;

        task open_sub_port(input int dst);
            ready_i[dst] = 1;
        endtask

        task close_sub_port(input int dst);
            ready_i[dst] = 0;
        endtask

    endclass

    manager mm [N_IN-1:0];
    subordinate ss [N_OUT-1:0];

    initial begin
        clk = 0;
        rst = 0;
        flush = 0;
        data_i = 0;
        valid_i = 0;
        last_i = 0;
        dest_i = 0;
        ready_i = 0;
        #(10*T);
        rst = 1;
        #(10*T);
        fork
            mm[0].manager_send(0,1,10);
            mm[2].manager_send(2,3,11);
            begin
                #(T*33);
                mm[1].manager_send(1,2,1);
            end
        join_none
        #(10*T);
        ss[2].open_sub_port(2);
        #(10*T);
        ss[3].open_sub_port(3);
        #(10*T);
        ss[1].open_sub_port(1);
        #(12*T);
        ss[3].close_sub_port(3);
        #(12*T);
        ss[3].open_sub_port(3);
        #(100*T);
        $finish;

    end

    always #(T/2) clk = ~clk;

endmodule