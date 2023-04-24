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
// File       : limber_gnrl_ramsp_nr.v
// Module     : limber_gnrl_ramsp_nr(RAMSPNR)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-1-17
// Version    : v1.0
// Description: Verilog module Single port RAM with write-enable, chip sel,
//              no reset, no output register.
//              Such that write data cost 1 clk while read data can derive immediately.
//
//-------------------------------------------------------------------------------------------
//(* DONT_TOUCH = "TRUE" *)
module limber_gnrl_ramsp_nr #(
    parameter DP = 64,
    parameter DW = 8,
    parameter AW = 6,
    parameter FORCE_X2ZERO = 0 
)
(
    input             clk,
    input  [DW-1  :0] din,
    input  [AW-1  :0] addr,
    input             cs,
    input             we,
    output [DW-1:0]   dout
);

    reg [DW-1:0] mem_r [0:DP-1];
    reg [AW-1:0] addr_r;
    wire wen;
    wire ren;

    assign ren = cs & ~we;
    assign wen = cs & we;

    always @(*)
    begin
        if (ren) begin
            addr_r <= addr;
        end
    end
 
    always @(posedge clk) begin
        if (wen) begin
            mem_r[addr] <= din;
        end
    end

    wire [DW-1:0] dout_pre;
    assign dout_pre = mem_r[addr_r];

    genvar i;
    generate
        if(FORCE_X2ZERO == 1) begin: force_x_to_zero
            for (i = 0; i < DW; i = i+1) begin:force_x_gen 
                assign dout[i] = (dout_pre[i] === 1'bx) ? 1'b0 : dout_pre[i];
            end
        end
        else begin:no_force_x_to_zero
            assign dout = dout_pre;
        end
    endgenerate
endmodule