/*----------------------------------------------------------------

Configurable Distribution Simple dual-port RAM.

This can be sythesis as LUT RAM automatically in FPGA.

-----------------------------------------------------------------*/
module gnrc_dist_dpram #(
    /* Data bit width @range: ">=1" */
    parameter DW = 32,
    /* RAM depth @range: ">=1" */
    parameter DP = 512,
    /* Set 1 to implement a register in input. @range: "{0,1}" */
    parameter IBUF = 0,
    /* Set 1 to implement a register in output. @range: "{0,1} */
    parameter OBUF = 0,
    /* Set 1 to initialize ram by zero @range: "{0,1}" */
    parameter INIT_BY_ZERO = 1,
    /* Initialize ram by a hex file, the initial value
    can also be downloaded to FPGA.
    Leave this empty to disable. @range: "file path" */
    parameter INIT_BY_FILE = "",
    /* Address bit width (auto-gen, do **NOT** change) @range: "$clog2(DP)" */
    parameter AW = $clog2(DP)
) (
    /* clock input */
    input logic clk_i,
    /* data input */
    input logic [DW-1:0] din_i,
    /* write enable input */
    input logic we_i,
    /* address */
    input logic [AW-1:0] addr_i,
    /* dual port address */
    input logic [AW-1:0] addrb_i,
    /* data output */
    output logic [DW-1:0] dout_o,
    /* dual port data output */
    output logic [DW-1:0] doutb_o
);

    logic [DW-1:0] ram [0:DP-1];

    if(INIT_BY_FILE) initial $readmemh(INIT_BY_FILE, ram);
    else if(INIT_BY_ZERO) initial for (int entry = 0; entry < DP; entry++) ram[entry] = 0;

    logic [DW-1:0] din;
    logic we;
    logic [AW-1:0] addr;
    logic [AW-1:0] addrb;

    if(IBUF)begin
        always @(posedge clk_i) begin
            din <= din_i;
            we <= we_i;
            addr <= addr_i;
            addrb <= addrb_i;
        end
    end else begin
        assign din = din_i;
        assign we = we_i;
        assign addr = addr_i;
        assign addrb = addrb_i;
    end

    always @(posedge clk_i)
        if (we) ram[addr] <= din;

    if(OBUF)begin
        always @(posedge clk_i) begin
            dout_o <= ram[addr];
            doutb_o <= ram[addrb];
        end
    end else begin
        assign dout_o = ram[addr];
        assign doutb_o = ram[addrb];
    end

endmodule