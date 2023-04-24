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
//-----------------------------------------------------------------------------
//
// Project    : Limber XPLOR
// File       : limber_gnrl_div.v
// Module     : limber_gnrl_div(DIV)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-7-21
// Version    : v1.0
// Description: Remiander Restoring Divider. DW clk/division.
//              Dividend and divisor must be positive.
//              
// ----------------------------------------------------------------------------
//   Revise
// / When       / Who     / What
// / 2022.7.21    qyl       first release.
//
//-----------------------------------------------------------------------------
module limber_gnrl_div#(
    parameter DW1 = 32,
    parameter DW2 = 32
)(
    input i_clk,
    input i_rst,

    input i_clr,

    input [DW1-1:0] i_dividend,
    input [DW2-1:0] i_divisor,
    input i_valid,

    output [DW1-1:0] o_quo,
    output [DW2-1:0] o_rem,
    output o_valid
    );

    localparam DW = DW1 + DW2;
    localparam CNT_DW = $clog2(DW1);

    reg [CNT_DW-1:0] cnt_r;
    reg [DW:0] dividend_ext;
    reg valid;
    wire start_flag = |cnt_r;

    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            cnt_r <= 0;
        end else begin
            if(i_clr|(cnt_r==DW1-1))
                cnt_r <= 0;
            else if(start_flag|(i_valid&~o_valid))
                cnt_r <= cnt_r+1;
        end
    end



    wire [DW-1:0] d = start_flag ? dividend_ext[DW-1:0] : {{DW2-1{1'b0}}, i_dividend, 1'b0};
    wire [DW2:0] sub_res = d[DW-1:DW1]-i_divisor;
    wire d_ge_s = ~sub_res[DW2];
    wire [DW:0] dividend_nxt = d_ge_s ? {sub_res[DW2-1:0],d[DW1-1:0],1'b1} : {d,1'b0};

    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            dividend_ext <= 0;
        end else begin
            dividend_ext <= dividend_nxt;
        end
    end

    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            valid <= 0;
        end else begin
            if(i_clr)
                valid <= 0;
            else if(cnt_r==DW1-1)
                valid <= 1'b1;
            else
                valid <= 1'b0;
        end
    end

    assign o_rem = dividend_ext[DW:DW-DW2+1];
    assign o_quo = dividend_ext[DW1-1:0];
    assign o_valid = valid;
endmodule