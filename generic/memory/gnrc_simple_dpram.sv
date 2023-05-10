/*----------------------------------------------------------------

Simple dual-port RAM.

This can be sythesis as BlockRAM primitive automatically in FPGA.

-----------------------------------------------------------------*/
module gnrc_simple_dpram #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* RAM depth @range: ">=1" */
    parameter DP = 512,
    /* RAM delay for simulation,
    It's recommended set DELAY = 1 in synthesis,
    otherwise a DFF chain of (DELAY-1) length will be implement
    between BRAM and dout @range: ">=1" */
    parameter DELAY = 1,
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
    /* Write port clock input */
    input logic wclk_i,
    /* Write port data input */
    input logic [DW-1:0] wdata_i,
    /* Write port enable input */
    input logic wen_i,
    /* Write port write enable input */
    input logic [MW-1:0] we_i,
    /* Write port write address input */
    input logic [AW-1:0] waddr_i,

    /* Read port clock input */
    input logic rclk_i,
    /* Read port enable input */
    input logic ren_i,
    /* Read port read address input */
    input logic [AW-1:0] raddr_i,
    /* Read port data output */
    output logic [DW-1:0] rdata_o
);

    gnrc_true_dpram #(
        .DW(DW),
        .DP(DP),
        .DELAY(DELAY),
        .OP_MODE(1), // fix to read first mode
        .BYTE_WRITE(BYTE_WRITE),
        .INIT_BY_ZERO(INIT_BY_ZERO),
        .INIT_BY_FILE(INIT_BY_FILE),
        .AW(AW),
        .MW(MW)
    ) u_ram (
        .clka_i  (wclk_i),
        .dina_i  (wdata_i),
        .ena_i   (wen_i),
        .wea_i   (we_i),
        .addra_i (waddr_i),
        .douta_o (),
        .clkb_i  (rclk_i),
        .dinb_i  ({DW{1'b0}}),
        .enb_i   (ren_i),
        .web_i   ({MW{1'b0}}),
        .addrb_i (raddr_i),
        .doutb_o (rdata_o)
    );
    
endmodule
