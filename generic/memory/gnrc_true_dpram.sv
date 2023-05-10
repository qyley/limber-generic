/*----------------------------------------------------------------

Ture dual-port RAM.

This can be sythesis as BlockRAM primitive automatically in FPGA.

-----------------------------------------------------------------*/
module gnrc_true_dpram #(
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
    /* port A clock input */
    input logic clka_i,
    /* port A data input */
    input logic [DW-1:0] dina_i,
    /* port A enable input */
    input logic ena_i,
    /* port A write enable input */
    input logic [MW-1:0] wea_i,
    /* port A read/write address input */
    input logic [AW-1:0] addra_i,
    /* port A data output */
    output logic [DW-1:0] douta_o,


    /* port B clock input */
    input logic clkb_i,
    /* port B data input */
    input logic [DW-1:0] dinb_i,
    /* port B enable input */
    input logic enb_i,
    /* port B write enable input */
    input logic [MW-1:0] web_i,
    /* port B read/write address input */
    input logic [AW-1:0] addrb_i,
    /* port B data output */
    output logic [DW-1:0] doutb_o
);
    // Declare the RAM variable
    logic [DW-1:0] ram [0:DP-1];
    logic [DW-1:0] qa, qb;

    
    if(INIT_BY_FILE) initial $readmemh(INIT_BY_FILE, ram);
    else if(INIT_BY_ZERO) initial for (int entry = 0; entry < DP; entry++) ram[entry] = 0;
    
    generate
        if(BYTE_WRITE)begin // byte_write
            for(genvar j=0;j<MW;j++)begin : byte_write
                if(j==MW-1) begin : bw_last
                    // Port A
                    always @ (posedge clka_i) begin
                        if(ena_i) begin
                            if (wea_i) begin
                                ram[addra_i][DW-1:j*8] <= dina_i[DW-1:j*8];
                            end
                        end
                    end
                    // Port B
                    always @ (posedge clkb_i) begin
                        if(enb_i) begin
                            if (web_i) begin
                                ram[addrb_i][DW-1:j*8] <= dinb_i[DW-1:j*8];
                            end
                        end
                    end
                end
                else begin : non_bw_last
                    // Port A
                    always @ (posedge clka_i) begin
                        if(ena_i) begin
                            if (wea_i[j]) begin
                                ram[addra_i][j*8+:8] <= dina_i[j*8+:8];
                            end
                        end
                    end
                    // Port B
                    always @ (posedge clkb_i) begin
                        if(enb_i) begin
                            if (web_i[j]) begin
                                ram[addrb_i][j*8+:8] <= dinb_i[j*8+:8];
                            end
                        end
                    end
                end
            end
            // Port A Read
            always @ (posedge clka_i) begin
                if(ena_i) begin
                    qa <= ram[addra_i];
                end
            end
            // Port B Read
            always @ (posedge clkb_i) begin
                if(enb_i) begin
                    qb <= ram[addrb_i];
                end
            end
        end else begin // non_byte_write
            // Port A Write
            always @ (posedge clka_i) begin
                if(ena_i) begin
                    if (wea_i) begin
                        ram[addra_i] <= dina_i;
                        if(OP_MODE==0)
                            qa <= dina_i;
                        else if(OP_MODE==1)
                            qa <= ram[addra_i];
                    end else begin
                        qa <= ram[addra_i];
                    end
                end
            end
            // Port B Write
            always @ (posedge clkb_i) begin
                if(enb_i) begin
                    if (web_i) begin
                        ram[addrb_i] <= dinb_i;
                        if(OP_MODE==0)
                            qb <= dinb_i;
                        else if(OP_MODE==1)
                            qb <= ram[addrb_i];
                    end else begin
                        qb <= ram[addrb_i];
                    end
                end
            end
            // Port A Read
            always @ (posedge clka_i) begin
                if(ena_i) begin
                    if (wea_i) begin
                        if(OP_MODE==0)
                            qa <= dina_i;
                        else if(OP_MODE==1)
                            qa <= ram[addra_i];
                        else
                            qa <= qa;
                    end else begin
                        qa <= ram[addra_i];
                    end
                end
            end
            // Port B Read
            always @ (posedge clkb_i) begin
                if(enb_i) begin
                    if (web_i) begin
                        if(OP_MODE==0)
                            qb <= dina_i;
                        else if(OP_MODE==1)
                            qb <= ram[addrb_i];
                        else
                            qb <= qb;
                    end else begin
                        qb <= ram[addrb_i];
                    end
                end
            end
        end
    endgenerate

    
    

    logic [DW-1:0] qa_d [DELAY:1];
    logic [DW-1:0] qb_d [DELAY:1];

    assign qa_d[1] = qa;
    assign qb_d[1] = qb;

    generate
        for(genvar i=1;i<DELAY;i++)begin : delay_gen
            always @(posedge clka_i) begin
                qa_d[i+1] <= qa_d[i];
            end
            always @(posedge clkb_i) begin
                qb_d[i+1] <= qb_d[i];
            end
        end
    endgenerate

    assign douta_o = qa_d[DELAY];
    assign doutb_o = qb_d[DELAY];

// pragma translate_off
    `ifndef VERILATOR
    write_a_collision : assert property (
        @(posedge clka_i) ((ena_i&&enb_i&&|(wea_i&web_i)) |-> ~(addra_i==addrb_i))) else
        $warning("Trying to write address %0d simultaneously in a TDPRAM(%m)", addra_i);
    write_b_collision : assert property (
        @(posedge clkb_i) ((ena_i&&enb_i&&|(wea_i&web_i)) |-> ~(addra_i==addrb_i))) else
        $warning("Trying to write address %0d simultaneously in a TDPRAM(%m)", addrb_i);
   `endif
// pragma translate_on


    
endmodule
