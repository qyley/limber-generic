///////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 qyley, UESTC 
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//-------------------------------------------------------------------------------------------
//
// Project    : Limber mcu
// File       : limber_gnrl_fifo_syn.v
// Module     : limber_gnrl_fifo_syn(FIFO)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-1-12
// Version    : v1.0
// Description: Verilog module sync FIFO.
//              
//
//-------------------------------------------------------------------------------------------

module limber_gnrl_fifo_syn # (
    parameter DW = 8,
    parameter AW = 8,
    parameter FORCE_X2ZERO = 0
)(
    input               clk,
    input               rst,
    input   [DW-1:0]    din,
    input               wen,
    input               ren,
    output              empty,
    output              full,
    output  [DW-1:0]    dout
);

    localparam DP = 1<<AW;
    wire    [AW-1:0]    fifo_waddr_r;
    wire    [AW-1:0]    fifo_waddr_nxt = fifo_waddr_r + 1;
    wire                fifo_waddr_wen = wen&~full;

    wire    [AW-1:0]    fifo_raddr_r;
    wire    [AW-1:0]    fifo_raddr_nxt = fifo_raddr_r + 1;
    wire                fifo_raddr_wen = ren&~empty;


    limber_gnrl_dfflr #(AW) dfflr_fifo_waddr(clk, rst, fifo_waddr_wen, fifo_waddr_nxt, fifo_waddr_r);
    limber_gnrl_dfflr #(AW) dfflr_fifo_raddr(clk, rst, fifo_raddr_wen, fifo_raddr_nxt, fifo_raddr_r);

    wire    [DW-1:0]    fifo_wdata = din;
    wire                fifo_wen = fifo_waddr_wen;
    wire    [DW-1:0]    fifo_rdata;
    wire                fifo_empty = fifo_waddr_r==fifo_raddr_r;
    wire                fifo_full = fifo_waddr_nxt==fifo_raddr_r;

    limber_gnrl_ramdp_nr #(
        .DP(DP),
        .DW(DW),
        .AW(AW),
        .FORCE_X2ZERO(FORCE_X2ZERO)
    ) u_ramdpnr_fifo (
        .clk   (clk),
        .din   (fifo_wdata),
        .waddr (fifo_waddr_r),
        .raddr (fifo_raddr_r),
        .cs    (1'b1),
        .we    (fifo_wen),
        .dout  (fifo_rdata)
    );

    assign empty = fifo_empty;
    assign full  = fifo_full;
    assign dout  = fifo_rdata;

endmodule