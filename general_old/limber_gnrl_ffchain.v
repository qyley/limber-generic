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
// File       : limber_gnrl_ffchain.v
// Module     : limber_gnrl_ffchain()
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-6-13
// Version    : v1.0
// Description: DFF chain.
//              
// ----------------------------------------------------------------------------
//   Revise
// / When       / Who     / What
// / 2022.6.28    qyl       first release.
//
//-----------------------------------------------------------------------------

module limber_gnrl_ffchain # (
    parameter DW = 1,
    parameter DP = 4
)(
    input               clk,
    input               rst_asyn,
    input   [DW-1:0]    si,
    output  [DW-1:0]    so
);

    reg [DW-1:0] q_r [DP-1:0];


    genvar i;
    generate
        for(i=0;i<DP;i=i+1)begin
            if(i==0)begin
                always @(posedge clk or posedge rst_asyn) begin : DFF_PROC
                    if(rst_asyn) begin
                        q_r[i] <= #1 0;
                    end
                    else 
                        q_r[i] <= #1 si;
                end
            end
            else begin
                always @(posedge clk or posedge rst_asyn) begin : DFF_PROC
                    if(rst_asyn) begin
                        q_r[i] <= #1 0;
                    end
                    else 
                        q_r[i] <= #1 q_r[i-1];
                end
            end
        end
    endgenerate
    

    assign so = q_r[DP-1];

endmodule