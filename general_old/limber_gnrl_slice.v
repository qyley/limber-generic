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
// File       : limber_gnrl_slice.v
// Module     : limber_gnrl_slice(SLICE)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-8-31
// Version    : v1.0
// Description: This module is an implementation of register slice. It can cut off the back-
//              pressure ready-valid combinational path in pipeline with 0 clock delay.
//
//-------------------------------------------------------------------------------------------

module limber_gnrl_slice # (
    parameter DW = 8
)(
    input               clk,
    input               rst,

    input               s_valid,
    output              s_ready,
    input   [DW-1:0]    s_data,

    output              m_valid,
    input               m_ready,
    output  [DW-1:0]    m_data
);

    wire s_hsk = s_valid & s_ready;
    wire m_hsk = m_valid & m_ready;

    reg slice_buf_valid;
    reg [DW-1:0] slice_buf_data;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            slice_buf_valid <= 0;
            slice_buf_data <= 0;
        end else begin
            if(~m_ready&&s_hsk) begin
                slice_buf_valid <= 1'b1;
                slice_buf_data <= s_data;
            end
            else if(slice_buf_valid&&m_hsk) begin
                slice_buf_valid <= 1'b0;
            end
        end
    end

    // path: slice_reg -> output (this path has been cut off from input to output)
    assign s_ready = ~slice_buf_valid;

    // path: input -> slice_mux -> output (this path hasn't been cut off)
    assign m_data = slice_buf_valid ? slice_buf_data : s_data;

    // path: input -> slice_or -> output (this path hasn't been cut off)
    assign m_valid = slice_buf_valid | s_valid;

endmodule