`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
//
// Project    : cmac
// File       : limber_gnrl_rand.v
// Module     : limber_gnrl_rand(RAND)
// Dependancy : 
// Software   : vivado2018.3
// Author     : qyley (qyley@foxmail.com)
// Date       : 2022-8-25
// Version    : v1.0
// Description: Random LFSR.
//              
// ----------------------------------------------------------------------------
//   Revise
// / When       / Who     / What
// / 2022.8.25    qyl       first release.
//
//-----------------------------------------------------------------------------
module limber_gnrl_rand#(
    parameter LFSR_LEN = 40, // must be 8-radix, range 8 ~ 64
    parameter RAND_LEN = 8,
    parameter SEED_LEN = 8
)(
    input                   i_clk,
    input   [SEED_LEN-1:0]  i_csr_seed_wdata,
    input                   i_csr_seed_wen,

    output  [SEED_LEN-1:0]  o_csr_seed_rdata,
    output  [RAND_LEN-1:0]  o_csr_rand_rdata
);

    wire [LFSR_LEN-1:0] csr_lfsr_r;
    wire [LFSR_LEN-1:0] csr_lfsr_nxt;

    // Create Feedback Polynomials.  Based on Application Note:
    // http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
    reg csr_lfsr_m; // M Polynomials
    always @(*) begin
        case (LFSR_LEN)
            8: begin
                csr_lfsr_m = csr_lfsr_r[8-1] ^~ csr_lfsr_r[6-1] ^~ csr_lfsr_r[5-1] ^~ csr_lfsr_r[4-1];
            end
            16: begin
                csr_lfsr_m = csr_lfsr_r[16-1] ^~ csr_lfsr_r[15-1] ^~ csr_lfsr_r[13-1] ^~ csr_lfsr_r[4-1];
            end
            24: begin
                csr_lfsr_m = csr_lfsr_r[24-1] ^~ csr_lfsr_r[23-1] ^~ csr_lfsr_r[22-1] ^~ csr_lfsr_r[17-1];
            end
            32: begin
                csr_lfsr_m = csr_lfsr_r[32-1] ^~ csr_lfsr_r[22-1] ^~ csr_lfsr_r[2-1] ^~ csr_lfsr_r[1-1];
            end
            40: begin
                csr_lfsr_m = csr_lfsr_r[40-1] ^~ csr_lfsr_r[38-1] ^~ csr_lfsr_r[21-1] ^~ csr_lfsr_r[19-1];
            end
            48: begin
                csr_lfsr_m = csr_lfsr_r[48-1] ^~ csr_lfsr_r[47-1] ^~ csr_lfsr_r[21-1] ^~ csr_lfsr_r[20-1];
            end
            56: begin
                csr_lfsr_m = csr_lfsr_r[56-1] ^~ csr_lfsr_r[55-1] ^~ csr_lfsr_r[35-1] ^~ csr_lfsr_r[34-1];
            end
            64: begin
                csr_lfsr_m = csr_lfsr_r[64-1] ^~ csr_lfsr_r[63-1] ^~ csr_lfsr_r[61-1] ^~ csr_lfsr_r[60-1];
            end
        endcase
    end

    if(LFSR_LEN > SEED_LEN) begin
        assign csr_lfsr_nxt = i_csr_seed_wen ? {csr_lfsr_r[LFSR_LEN-2:SEED_LEN-1], i_csr_seed_wdata}
                                             : {csr_lfsr_r[LFSR_LEN-2:0]         , csr_lfsr_m      };
    end
    else begin
        assign csr_lfsr_nxt = i_csr_seed_wen ? i_csr_seed_wdata : {csr_lfsr_r[LFSR_LEN-2:0], csr_lfsr_m};
    end
    
    limber_gnrl_dff #(LFSR_LEN) dff_lsfr(i_clk, csr_lfsr_nxt, csr_lfsr_r);
    
    assign o_csr_seed_rdata = csr_lfsr_r[SEED_LEN-1:0];
    assign o_csr_rand_rdata = csr_lfsr_r[LFSR_LEN-1:LFSR_LEN-RAND_LEN];

endmodule