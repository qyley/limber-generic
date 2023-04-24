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
// File       : limber_gnrl_fifo_asyn.v
// Module     : limber_gnrl_fifo_asyn(FIFO_ASYN)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-1-12
// Version    : v1.0
// Description: Verilog module async FIFO.
//              
//
//-------------------------------------------------------------------------------------------
module limber_gnrl_fifo_asyn # (
    parameter DW = 3,
    parameter AW = 3
)(
    input               wclk,
    input               rclk,
    input               wrst,
    input               rrst,
    input   [DW-1:0]    din,
    input               wen,
    input               ren,
    output              aempty,
    output              empty,
    output              afull,
    output              full,
    output  [DW-1:0]    dout
);

    localparam DP = 1<<AW;
    // write control @ wclk
    wire                wfull;
    wire    [AW-1+1:0]  wptr_bin_r;
    wire    [AW-1+1:0]  wptr_bin_nxt = wptr_bin_r + (~wfull&wen);

    wire    [AW-1+1:0]  wptr_gray_r;
    wire    [AW-1+1:0]  wptr_gray_nxt = (wptr_bin_nxt>>1)^wptr_bin_nxt;

    wire    [AW-1+1:0]  rptr_gray_wclk;
    wire    [AW-1:0]    waddr = wptr_bin_r[AW-1:0];

    limber_gnrl_dffr #(AW+1) dffr_fifo_wptr_gray(wclk, wrst, wptr_gray_nxt, wptr_gray_r);
    limber_gnrl_dffr #(AW+1) dffr_fifo_wptr_bin(wclk, wrst, wptr_bin_nxt, wptr_bin_r);

    assign wfull = rptr_gray_wclk=={~wptr_gray_r[AW:AW-1],wptr_gray_r[AW-2:0]};
    wire wempty = rptr_gray_wclk==wptr_gray_r;

    // read control @ rclk
    wire                rempty;
    wire    [AW-1+1:0]  rptr_bin_r;
    wire    [AW-1+1:0]  rptr_bin_nxt = rptr_bin_r + (~rempty&ren);

    wire    [AW-1+1:0]  rptr_gray_r;
    wire    [AW-1+1:0]  rptr_gray_nxt = (rptr_bin_nxt>>1)^rptr_bin_nxt;

    wire    [AW-1+1:0]  wptr_gray_rclk;
    wire    [AW-1:0]    raddr = rptr_bin_r[AW-1:0];

    limber_gnrl_dffr #(AW+1) dffr_fifo_rptr_gray(rclk, rrst, rptr_gray_nxt, rptr_gray_r);
    limber_gnrl_dffr #(AW+1) dffr_fifo_rptr_bin(rclk, rrst, rptr_bin_nxt, rptr_bin_r);

    assign rempty = wptr_gray_rclk==rptr_gray_r;
    wire rfull = wptr_gray_rclk=={~rptr_gray_r[AW:AW-1], rptr_gray_r[AW-2:0]};

    // ptr synchronizer
    limber_gnrl_flop_sync #(2,AW+1) fsync_rptr_wclk(wclk, wrst, rptr_gray_r, rptr_gray_wclk); 
    limber_gnrl_flop_sync #(2,AW+1) fsync_wptr_rclk(rclk, rrst, wptr_gray_r, wptr_gray_rclk); 

    // RAM
    limber_gnrl_ramdp_nr #(
        .DP(DP),
        .DW(DW),
        .AW(AW)
    ) u_ramdpnr_fifo (
        .clk   (wclk),
        .din   (din),
        .waddr (waddr),
        .raddr (raddr),
        .cs    (1'b1),
        .we    (~wfull&wen),
        .dout  (dout)
    );

    assign empty  = wempty;
    assign aempty = rempty;
    assign full   = rfull;
    assign afull  = wfull;

endmodule