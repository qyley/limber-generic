`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
//
// Project    : cmac
// File       : limber_gnrl_crc32.v
// Module     : limber_gnrl_crc32(CRC32)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-8-25
// Version    : v1.0
// Description: Ethernet crc32 check code.
//              
// ----------------------------------------------------------------------------
//   Revise
// / When       / Who     / What
// / 2022.8.25    qyl       first release.
//
//-----------------------------------------------------------------------------
module limber_gnrl_crc32(

    input           i_clk,
    input           i_rstn,

    input   [7:0]   i_data,             //input a byte, bit7 is the MSB
    input           i_data_vld,         //i_data valid if high
    input           i_clr,              //clear crc_data to 0xffff_ffff
    output  [31:0]  o_crc_data,         //output with 1 clk delay(register output)
    output  [31:0]  o_crc_next          //output immediately(combinational logic output)

);

    //*****************************************************
    //**                    main code
    //*****************************************************

    reg [31:0] crc_data;
    wire [31:0] crc_next;


    // reverse input bit order due to the algorithm 
    wire    [7:0]   data_t;

    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin
            assign data_t[i] = i_data[8-1-i];
        end

        for(i=0; i<32; i=i+1) begin
            assign o_crc_data[i] = crc_data[32-1-i];
            assign o_crc_next[i] = crc_next[32-1-i];
        end
    endgenerate

    //CRC32 Generating polynomial G(x)= x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 
    //                                + x^10 + x^8  + x^7  + x^5  + x^4  + x^2  + x^1  + 1

    assign crc_next[0] = crc_data[24] ^ crc_data[30] ^ data_t[0] ^ data_t[6];
    assign crc_next[1] = crc_data[24] ^ crc_data[25] ^ crc_data[30] ^ crc_data[31] 
                         ^ data_t[0] ^ data_t[1] ^ data_t[6] ^ data_t[7];
    assign crc_next[2] = crc_data[24] ^ crc_data[25] ^ crc_data[26] ^ crc_data[30] 
                         ^ crc_data[31] ^ data_t[0] ^ data_t[1] ^ data_t[2] ^ data_t[6] 
                         ^ data_t[7];
    assign crc_next[3] = crc_data[25] ^ crc_data[26] ^ crc_data[27] ^ crc_data[31] 
                         ^ data_t[1] ^ data_t[2] ^ data_t[3] ^ data_t[7];
    assign crc_next[4] = crc_data[24] ^ crc_data[26] ^ crc_data[27] ^ crc_data[28] 
                         ^ crc_data[30] ^ data_t[0] ^ data_t[2] ^ data_t[3] ^ data_t[4] 
                         ^ data_t[6];
    assign crc_next[5] = crc_data[24] ^ crc_data[25] ^ crc_data[27] ^ crc_data[28] 
                         ^ crc_data[29] ^ crc_data[30] ^ crc_data[31] ^ data_t[0] 
                         ^ data_t[1] ^ data_t[3] ^ data_t[4] ^ data_t[5] ^ data_t[6] 
                         ^ data_t[7];
    assign crc_next[6] = crc_data[25] ^ crc_data[26] ^ crc_data[28] ^ crc_data[29] 
                         ^ crc_data[30] ^ crc_data[31] ^ data_t[1] ^ data_t[2] ^ data_t[4] 
                         ^ data_t[5] ^ data_t[6] ^ data_t[7];
    assign crc_next[7] = crc_data[24] ^ crc_data[26] ^ crc_data[27] ^ crc_data[29] 
                         ^ crc_data[31] ^ data_t[0] ^ data_t[2] ^ data_t[3] ^ data_t[5] 
                         ^ data_t[7];
    assign crc_next[8] = crc_data[0] ^ crc_data[24] ^ crc_data[25] ^ crc_data[27] 
                         ^ crc_data[28] ^ data_t[0] ^ data_t[1] ^ data_t[3] ^ data_t[4];
    assign crc_next[9] = crc_data[1] ^ crc_data[25] ^ crc_data[26] ^ crc_data[28] 
                         ^ crc_data[29] ^ data_t[1] ^ data_t[2] ^ data_t[4] ^ data_t[5];
    assign crc_next[10] = crc_data[2] ^ crc_data[24] ^ crc_data[26] ^ crc_data[27] 
                         ^ crc_data[29] ^ data_t[0] ^ data_t[2] ^ data_t[3] ^ data_t[5];
    assign crc_next[11] = crc_data[3] ^ crc_data[24] ^ crc_data[25] ^ crc_data[27] 
                         ^ crc_data[28] ^ data_t[0] ^ data_t[1] ^ data_t[3] ^ data_t[4];
    assign crc_next[12] = crc_data[4] ^ crc_data[24] ^ crc_data[25] ^ crc_data[26] 
                         ^ crc_data[28] ^ crc_data[29] ^ crc_data[30] ^ data_t[0] 
                         ^ data_t[1] ^ data_t[2] ^ data_t[4] ^ data_t[5] ^ data_t[6];
    assign crc_next[13] = crc_data[5] ^ crc_data[25] ^ crc_data[26] ^ crc_data[27] 
                         ^ crc_data[29] ^ crc_data[30] ^ crc_data[31] ^ data_t[1] 
                         ^ data_t[2] ^ data_t[3] ^ data_t[5] ^ data_t[6] ^ data_t[7];
    assign crc_next[14] = crc_data[6] ^ crc_data[26] ^ crc_data[27] ^ crc_data[28] 
                         ^ crc_data[30] ^ crc_data[31] ^ data_t[2] ^ data_t[3] ^ data_t[4]
                         ^ data_t[6] ^ data_t[7];
    assign crc_next[15] =  crc_data[7] ^ crc_data[27] ^ crc_data[28] ^ crc_data[29]
                         ^ crc_data[31] ^ data_t[3] ^ data_t[4] ^ data_t[5] ^ data_t[7];
    assign crc_next[16] = crc_data[8] ^ crc_data[24] ^ crc_data[28] ^ crc_data[29] 
                         ^ data_t[0] ^ data_t[4] ^ data_t[5];
    assign crc_next[17] = crc_data[9] ^ crc_data[25] ^ crc_data[29] ^ crc_data[30] 
                         ^ data_t[1] ^ data_t[5] ^ data_t[6];
    assign crc_next[18] = crc_data[10] ^ crc_data[26] ^ crc_data[30] ^ crc_data[31] 
                         ^ data_t[2] ^ data_t[6] ^ data_t[7];
    assign crc_next[19] = crc_data[11] ^ crc_data[27] ^ crc_data[31] ^ data_t[3] ^ data_t[7];
    assign crc_next[20] = crc_data[12] ^ crc_data[28] ^ data_t[4];
    assign crc_next[21] = crc_data[13] ^ crc_data[29] ^ data_t[5];
    assign crc_next[22] = crc_data[14] ^ crc_data[24] ^ data_t[0];
    assign crc_next[23] = crc_data[15] ^ crc_data[24] ^ crc_data[25] ^ crc_data[30] 
                          ^ data_t[0] ^ data_t[1] ^ data_t[6];
    assign crc_next[24] = crc_data[16] ^ crc_data[25] ^ crc_data[26] ^ crc_data[31] 
                          ^ data_t[1] ^ data_t[2] ^ data_t[7];
    assign crc_next[25] = crc_data[17] ^ crc_data[26] ^ crc_data[27] ^ data_t[2] ^ data_t[3];
    assign crc_next[26] = crc_data[18] ^ crc_data[24] ^ crc_data[27] ^ crc_data[28] 
                          ^ crc_data[30] ^ data_t[0] ^ data_t[3] ^ data_t[4] ^ data_t[6];
    assign crc_next[27] = crc_data[19] ^ crc_data[25] ^ crc_data[28] ^ crc_data[29] 
                          ^ crc_data[31] ^ data_t[1] ^ data_t[4] ^ data_t[5] ^ data_t[7];
    assign crc_next[28] = crc_data[20] ^ crc_data[26] ^ crc_data[29] ^ crc_data[30] 
                          ^ data_t[2] ^ data_t[5] ^ data_t[6];
    assign crc_next[29] = crc_data[21] ^ crc_data[27] ^ crc_data[30] ^ crc_data[31] 
                          ^ data_t[3] ^ data_t[6] ^ data_t[7];
    assign crc_next[30] = crc_data[22] ^ crc_data[28] ^ crc_data[31] ^ data_t[4] ^ data_t[7];
    assign crc_next[31] = crc_data[23] ^ crc_data[29] ^ data_t[5];

    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn)
            crc_data <= 32'hff_ff_ff_ff;
        else begin
            if(i_clr)
                crc_data <= 32'hff_ff_ff_ff;
            else if(i_data_vld)
                crc_data <= crc_next;
        end
    end

endmodule