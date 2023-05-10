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
// File       : limber_gnrl_dffr.v
// Module     : limber_gnrl_dffr(DFF)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-1-12
// Version    : v1.0
// Description: Verilog module DFF with no Load-enable, reset.
//              origin from hbird e203 sirv_gnrl_dff
//
//-------------------------------------------------------------------------------------------

module limber_gnrl_dffr # (
    parameter DW = 8
) (
    input               clk,
    input               rst,
    input   [DW-1:0]    dnxt,
    output  [DW-1:0]    qout
);

    reg [DW-1:0] qout_r = {DW{1'b0}};

    always @(posedge clk or posedge rst)
    begin : DFFLR_PROC
        if (rst == 1'b1)
            qout_r <= {DW{1'b0}};
        else 
            qout_r <= #1 dnxt;
    end

    assign qout = qout_r;

endmodule