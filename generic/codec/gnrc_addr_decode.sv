/*----------------------------------------------------------------
| addr decoder.
| There are 2 Format of Address Mapping Rule

1. Top of range (TOR)

  In ``TOR`` format, the address space will seperated into NR+1 intervals
  by NR Address Mapping Rule. The range of Eech intervals is as below:

    [0, MAP[0]-1], [MAP[1], MAP[2]-1] ..., [MAP[n], MAP[n+1]-1] ..., [MAP[NR], 2^AW-1]

  The value of ``MAP`` rules must be increasing across its 1st dimension

  For example, try:

.. code:: verilog

    // range of intervals are: [0,99], [100,199], [200,255]
    localparam logic[1:0][7:0] RULE_MAP_TOR = {
        8'd200,
        8'd100
    };

2. Naturally Aligned Power-Of-Two (NAPOT)

  In ``NAPOT`` format, the address space will be described as ``yyy...y011...1``
  where the ``yyy...y`` can be any number. The ``yyy...y011...1`` means
  the address space start from ``yyy...y000...0`` and end in ``yyy...y111...1`` .
  
  Requires the start address of ``MAP`` rules must be increasing across its
  1st dimension and with no overlap.

  For example, try:

.. code:: verilog

    // range of address space are: [0,127], [128,191]
    // and the out of range (i.e. non-allocated) space are: [192,255]
    localparam logic[1:0][7:0] RULE_MAP_NAPOT = {
        8'b1001_1111, // 1000_0000~1011_1111
        8'b0011_1111  // 0000_0000~0111_1111
    };

-----------------------------------------------------------------*/
module gnrc_addr_decode #(
    /* address bit width @range: ">=1" */
    parameter int unsigned AW = 32,
    /* num of address mapping rule @range: ">=1" */
    parameter int unsigned NR = 1,
    /* set 1 use `NAPOT` as the Format of Address Mapping Rule,
    set 0 use `TOR` as the Format of Address Mapping Rule @range: "{0,1}" */
    parameter bit NAPOT = 1,
    /* address mapping rule data structure @range: "!=0,-1" */
    parameter logic[NR-1:0][AW-1:0] MAP = 'b0,
    /* mapping range idx bitwidth (auto-gen,do **NOT** change) @range: ">=0" */
    localparam CW = $clog2(NR+(NAPOT==0))
)(
    /* address input */
    input  logic[AW-1:0] addr_i,
    /* mapping range idx */
    output logic[CW-1:0] map_idx_o,
    /* mapping out of range*/
    output logic map_out_of_range_o
);

    function automatic int unsigned find_first_one (input logic [AW-1:0] vec);
        for(int unsigned i=0; i<AW; i++)begin
            if(vec[i])begin
                return i;
            end
        end
        return AW;
    endfunction
    
    generate
        if(NAPOT)begin : gen_napot_addr_decode
    
            logic [NR-1:0] addr_eq_rule_code;
    
            for(genvar rule_n = 0; rule_n < NR; rule_n++)begin
                localparam AW_WILDCARD = find_first_one(~MAP[rule_n]);
                assign addr_eq_rule_code[rule_n] = addr_i[AW-1:AW_WILDCARD+1] == MAP[rule_n][AW-1:AW_WILDCARD+1];
            end
    
            gnrc_onehot2bin #(.N(NR)) inst_gnrc_onehot2bin (.onehot_i(addr_eq_rule_code), .bin_o(map_idx_o));
    
            assign map_out_of_range_o = ~|addr_eq_rule_code;

            
            
        end
        else begin : gen_tor_addr_decode
    
            logic [NR-1:0] addr_ge_rule_code;
    
            for(genvar rule_n = 0; rule_n < NR; rule_n++)begin
                localparam AW_WILDCARD = find_first_one(MAP[rule_n]);
                assign addr_ge_rule_code[rule_n] = addr_i[AW-1:AW_WILDCARD] > MAP[rule_n][AW-1:AW_WILDCARD];
            end
    
            gnrc_therm2bin #(.N(NR)) inst_gnrc_therm2bin (.therm_i(addr_ge_rule_code), .bin_o(map_idx_o));
            assign map_out_of_range_o = 'b0;
        end
    
    endgenerate

    initial begin : param_checker
        for(int i=1; i<AW; i++) begin
            assert (MAP[i]>MAP[i-1]) else
            $fatal(1, "[%m] illegal mapping rule, The value of ``MAP`` rules must be increasing across its 1st dimension.");
        end
    end

endmodule

