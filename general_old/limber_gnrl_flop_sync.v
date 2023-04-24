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
// File       : limber_gnrl_flop_sync.v
// Module     : limber_gnrl_flop_sync(FLOP_SYNC)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-3-23
// Version    : v1.0
// Description: Verilog module N-depth DFF Synchronizer.
//              
//
//-------------------------------------------------------------------------------------------
module limber_gnrl_flop_sync # (
    parameter DP = 2,
    parameter DW = 1
)(
    input clk,
    input rst,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    wire [DW-1:0] din_d[DP:1];
    limber_gnrl_dffr #(DW) dffr_flop_sync_d(clk, rst, din, din_d[1]);
    genvar i;
    generate
        for (i=1; i<DP; i=i+1) begin
            limber_gnrl_dffr #(DW) dffr_flop_sync_d(clk, rst, din_d[i], din_d[i+1]);
        end
    endgenerate

    assign dout = din_d[DP];

endmodule