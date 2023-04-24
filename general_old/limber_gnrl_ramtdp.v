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
// File       : limber_gnrl_ramtdp.v
// Module     : limber_gnrl_ramtdp(RAMTDP)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-7-10
// Version    : v1.0
// Description: Verilog module Ture Dual port RAM.
//              write data has 1 clk delay.
//
//-------------------------------------------------------------------------------------------
//(* DONT_TOUCH = "TRUE" *)
module limber_gnrl_ramtdp #(
    parameter DP = 4,
    parameter DW = 3,
    parameter AW = 2,
    parameter DLY = 1,
    parameter FORCE_X2ZERO = 0 
)
(
    input               clk,
    input               cs,
    input   [DW-1:0]    dina,
    input   [AW-1:0]    addra,
    input               wa,
    input   [DW-1:0]    dinb,
    input   [AW-1:0]    addrb,
    input               wb,
    output  [DW-1:0]    douta,
    output  [DW-1:0]    doutb
);

    reg [DW-1:0] mem_r [0:DP-1];
    reg [AW-1:0] addra_r;
    reg [AW-1:0] addrb_r;

    always @(*) begin
        if (~wa&cs) begin
            addra_r <= addra;
        end
        if (~wb&cs) begin
            addrb_r <= addrb;
        end
    end

    always @(posedge clk) begin
        if (wa&cs) begin
            mem_r[addra] <= dina;
        end
        if (wb&cs&~(wa&addra==addrb)) begin
            mem_r[addrb] <= dinb;
        end

    end

    reg [DW-1:0] douta_delay [DLY:0];
    reg [DW-1:0] doutb_delay [DLY:0];
    wire [DW-1:0] douta_pre = douta_delay[DLY];
    wire [DW-1:0] doutb_pre = doutb_delay[DLY];

    always @(*) begin
        douta_delay[0] = mem_r[addra_r];
        doutb_delay[0] = mem_r[addrb_r];
    end

    genvar i;
    generate
        for(i=1;i<=DLY;i=i+1)begin
            always @(posedge clk) begin
                douta_delay[i] <= douta_delay[i-1];
                doutb_delay[i] <= doutb_delay[i-1];
            end
        end

        if(FORCE_X2ZERO == 1) begin
            for (i = 0; i < DW; i = i+1) begin
                assign douta[i] = (douta_pre[i] === 1'bx) ? 1'b0 : douta_pre[i];
                assign doutb[i] = (doutb_pre[i] === 1'bx) ? 1'b0 : doutb_pre[i];
            end
        end
        else begin
            assign doutb = doutb_pre;
            assign douta = douta_pre;
        end
    endgenerate

endmodule