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
// File       : limber_gnrl_latch.v
// Module     : limber_gnrl_latch(LATCH)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-1-12
// Version    : v1.0
// Description: Verilog module Latch with Load-enable, no reset.
//              origin from hbird e203 sirv_gnrl_ltch
//
//-------------------------------------------------------------------------------------------

module limber_gnrl_latch # (
    parameter DW = 8
)(
    input               lden,
    input   [DW-1:0]    dnxt,
    output  [DW-1:0]    qout
);

    reg [DW-1:0] qout_r = {DW{1'b0}};
    initial qout_r = 0;

    always @(*) begin : LATCH_PROC
        if(lden == 1'b1)
            qout_r <= dnxt;
    end

    assign qout = qout_r;

endmodule