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
// Project    : Limber IoT NP
// File       : limber_gnrl_rising.v
// Module     : limber_gnrl_rising(RISE)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley(qyley@foxmail.com)
// Date       : 2022-5-18
// Version    : v1.0
// Description: Rising edge detect.
//
//-------------------------------------------------------------------------------------------
module limber_gnrl_rising(
    input   i_clk,
    input   i_rst,
    input   i_a,
    output  o_a_pulse
);
    reg a_d1;
    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            a_d1 <= 0;
        end else begin
            a_d1 <= i_a;
        end
    end

    assign o_a_pulse = i_a&~a_d1;

endmodule