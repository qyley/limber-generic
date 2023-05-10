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
// File       : limber_gnrl_slot_timer.v
// Module     : limber_gnrl_slot_timer(STMR)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley(qyley@foxmail.com)
// Date       : 2022-10-28
// Version    : v1.0
// Description: This is a value-configurable timer. Function is as blow:
//              1. When i_set=1, i_value will be set as expired time.
//              2. When i_clear=1, the timing number will be clear to 0.
//              3. When i_start=1, timing number will increase at each clock posedge,
//                 when i_start=0, timing will be suspend.
//              4. When timing number reach the expired time, o_expired will set 1,
//                 and timing will stop. Set i_clear=1 to clear and relaunch the timing.
//
//-------------------------------------------------------------------------------------------
module limber_gnrl_slot_timer#(
    parameter TW = 8,      // Timer bitwidth
    parameter SW = 16,     // Slot bitwidth
    parameter IV = 100,    // Initial value
    parameter TB = 125     // Time tick base
)(
    input               i_clk,
    input               i_rst,
    input               i_start,
    input               i_clear,
    input   [TW-1:0]    i_timing_value,
    input   [SW-1:0]    i_slot_value,
    input               i_set,
    output              o_expired
);

    reg [TW-1:0] timing_value_r;
    reg [SW-1:0] slot_value_r;

    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            timing_value_r <= IV;
            slot_value_r <= 1;
        end else begin
            if(i_set) begin
                timing_value_r <= i_timing_value;
                slot_value_r <= i_slot_value;
            end
        end
    end

    reg [$clog2(TB)-1:0] tic_cnt_r;
    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            tic_cnt_r <= 0;
        end else begin
            if(i_clear)
                tic_cnt_r <= 0;
            else if(i_start)
                tic_cnt_r <= (tic_cnt_r==TB-1) ? 0 : tic_cnt_r + 1;
        end
    end

    reg [TW-1:0] timing_cnt_r;
    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            timing_cnt_r <= 0;
        end else begin
            if(i_clear)
                timing_cnt_r <= 0;
            else if(i_start && tic_cnt_r==(TB-1))
                timing_cnt_r <= (timing_cnt_r==timing_value_r) ? {SW{1'b0}} : timing_cnt_r + 1;
        end
    end

    reg  [SW-1:0] slot_cnt_r;
    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            slot_cnt_r <= 0;
        end else begin
            if(i_clear)
                slot_cnt_r <= 0;
            else if(i_start && timing_cnt_r==timing_value_r)
                slot_cnt_r <= slot_cnt_r + 1;
        end
    end

    reg expired_flag_r;
    always @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            expired_flag_r <= 0;
        end else begin
            if(i_clear)
                expired_flag_r <= 0;
            else if(slot_cnt_r==slot_value_r && timing_cnt_r==timing_value_r)
                expired_flag_r <= 1;
        end
    end

    assign o_expired = expired_flag_r;

endmodule