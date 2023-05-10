/*----------------------------------------------------------------

Single-port RAM.

This can be sythesis as BlockRAM primitive automatically in FPGA.

-----------------------------------------------------------------*/
module gnrc_spram #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* RAM depth @range: ">=1" */
    parameter DP = 512,
    /* RAM delay for simulation,
    It's recommended set DELAY = 1 in synthesis,
    otherwise a DFF chain of (DELAY-1) length will be implement
    between BRAM and dout @range: ">=1" */
    parameter DELAY = 1,
    /* Operationg Mode, 0 for Write-First, 1 for Read-First, 2 for No-Change.
    **ONLY** support Read-First when BYTE_WRITE enable @range: "{0,1,2}"*/
    parameter OP_MODE = 0,
    /* Set 1 to enable byte write @range: "{0,1}"*/
    parameter BYTE_WRITE = 0,
    /* Set 1 to initialize ram by zero @range: "{0,1}" */
    parameter INIT_BY_ZERO = 1,
    /* Initialize ram by a hex file, the initial value
    can also be downloaded to FPGA.
    Leave this empty to disable. @range: "file path" */
    parameter INIT_BY_FILE = "",
    /* Address bit width (auto-gen, do **NOT** change) @range: "$clog2(DP)" */
    parameter AW = $clog2(DP),
    /* Write enable bit width (auto-gen, do **NOT** change)
    @range: "$ceil(DW/8) if BYTE_WRITE, 1 otherwise" */
    parameter MW = BYTE_WRITE ? $ceil(DW/8) : 1
) (
    /* clock input */
    input logic clk_i,
    /* data input */
    input logic [DW-1:0] din_i,
    /* enable input */
    input logic en_i,
    /* write enable input */
    input logic [MW-1:0] we_i,
    /* write/read address input */
    input logic [AW-1:0] addr_i,
    /* data output */
    output logic [DW-1:0] dout_o
);

    gnrc_true_dpram #(
        .DW(DW),
        .DP(DP),
        .DELAY(DELAY),
        .OP_MODE(1),
        .BYTE_WRITE(BYTE_WRITE),
        .INIT_BY_ZERO(INIT_BY_ZERO),
        .INIT_BY_FILE(INIT_BY_FILE),
        .AW(AW),
        .MW(MW)
    ) u_ram (
        .clka_i  (clk_i),
        .dina_i  (din_i),
        .ena_i   (en_i),
        .wea_i   (we_i),
        .addra_i (addr_i),
        .douta_o (dout_o),
        .clkb_i  (1'b0),
        .dinb_i  ({DW{1'b0}}),
        .enb_i   (1'b0),
        .web_i   ({MW{1'b0}}),
        .addrb_i ({AW{1'b0}}),
        .doutb_o ()
    );
    
endmodule
