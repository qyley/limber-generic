/*----------------------------------------------------------------
| Register Slice
|
| Decouples two sides of a ready/valid handshake to allow back-to-back transfers
| without a combinational path between input and output, thus pipelining the path.
|
| There are 4 kind of type for register slice:

Pass Through
    Connect input to output directly. Not pipelining.
    Enable if ``FORWARD_Q=0`` and ``BACKWARD_Q=0``
Forward Registered
    `data_i` and `valid_i` will be registered to decouple the forward path.
    Enable if ``FORWARD_Q=1`` and ``BACKWARD_Q=0``
Backward Registered
    `ready_i` will be registered to decouple the backward path.
    Enable if ``FORWARD_Q=0`` and ``BACKWARD_Q=1``
Full Registered
    registered all input signal to decouple the path thoroughly between input and output.
    Enable if ``FORWARD_Q=1`` and ``BACKWARD_Q=1``

| 
-----------------------------------------------------------------*/
module gnrc_slice#(
    /* Data width of the payload in bits. Lose efficacy if `DTYPE` is overwritten. @range: ">=1"*/
    parameter int unsigned DW      = 1,
    /* Set to 1 to enable Forward register. @range: "{0,1}" */
    parameter bit          FORWARD_Q   = 1,
    /* Set to 1 to enable Backward register. @range: "{0,1}" */
    parameter bit          BACKWARD_Q   = 1,
    /* Data type of the payload, can be overwritten with custom type. 
    Only use of `DW`. @range: "logic [DW-1:0]" */
    parameter type         DTYPE   = logic [DW-1:0]
)(
    /* Clock, positive edge triggered. */
    input logic         clk_i,
    /* Asynchronous reset, active low. */
    input logic         rst_ni,
    /* Clears the registed data in slice. makes **NO** effect on combinational path */
    input logic         flush_i,
    /* Input source is valid. */
    input logic         valid_i,
    /* Input source data. */
    input DTYPE         data_i,
    /* Input destination is ready. */
    output logic        ready_o,
    /* Output source is valid. */
    output logic        valid_o,
    /* Output source data. */
    output DTYPE        data_o,
    /* Output destination is ready. */
    input logic         ready_i
);


  if(~FORWARD_Q&&~BACKWARD_Q) begin
    assign ready_o = ready_i;
    assign valid_o = valid_i;
    assign data_o = data_i;
  end


  if(FORWARD_Q&&~BACKWARD_Q) begin

    // skid buffer
    DTYPE buf_q;
    logic buf_full_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf_q <= 0;
      end else begin
        if(valid_i&ready_o&~flush_i)begin
          buf_q <= data_i;
        end
      end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf_full_q <= 0;
      end else begin
        if(flush_i)begin
          buf_full_q <= 1'b0;
        end else begin
          if(valid_i&ready_o)begin
            buf_full_q <= 1'b1;
          end else if(ready_i&valid_o) begin
            buf_full_q <= 1'b0;
          end
        end
      end
    end

    // slice ready if destination ready
    // or destination stall but buffer is not full.
    assign ready_o = ready_i | ~ready_i&~buf_full_q;
    assign valid_o = buf_full_q;
    assign data_o = buf_q;
  end


  if(~FORWARD_Q&&BACKWARD_Q) begin

    // skid buffer
    DTYPE buf_q;
    logic buf_full_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf_q <= 0;
      end else begin
        if(valid_i&ready_o&~flush_i)begin
          buf_q <= data_i;
        end
      end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf_full_q <= 0;
      end else begin
        if(flush_i)begin
          buf_full_q <= 1'b0;
        end else begin
          if(valid_i&ready_o&~ready_i)begin
            buf_full_q <= 1'b1;
          end else if(ready_i&valid_o) begin
            buf_full_q <= 1'b0;
          end
        end
      end
    end

    // slice ready if buffer is not full
    assign ready_o = ~buf_full_q;
    assign valid_o = buf_full_q | valid_i;
    assign data_o = buf_full_q ? buf_q : data_i;
  end

    
  if(FORWARD_Q&&BACKWARD_Q) begin


    DTYPE buf1_q, buf2_q;
    logic buf1_full_q, buf2_full_q;

    // skid buffer 1
    // fill this buffer when ready_o & valid_i
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf1_q <= 0;
      end else begin
        if(valid_i&ready_o&~flush_i)begin
          buf1_q <= data_i;
        end
      end
    end

    
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf1_full_q <= 0;
      end else begin
        if(flush_i)begin
          buf1_full_q <= 1'b0;
        end else begin
          if(valid_i&ready_o)begin
            buf1_full_q <= 1'b1;
          end else if(ready_i&valid_o&~buf2_full_q) begin
            buf1_full_q <= 1'b0;
          end
        end
      end
    end


    // skid buffer 2
    // fill this buffer when buffer1 is full and destination is not ready
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf2_q <= 0;
      end else begin
        if(valid_i&ready_o&~ready_i&buf1_full_q&~flush_i)begin
          buf2_q <= buf1_q;
        end
      end
    end

    
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        buf2_full_q <= 0;
      end else begin
        if(flush_i)begin
          buf2_full_q <= 1'b0;
        end else begin
          if(valid_i&ready_o&~ready_i&buf1_full_q)begin
            buf2_full_q <= 1'b1;
          end else if(ready_i&valid_o&buf2_full_q) begin
            buf2_full_q <= 1'b0;
          end
        end
      end
    end

    assign ready_o = ~buf2_full_q | ~buf1_full_q ;
    assign valid_o =  buf2_full_q |  buf1_full_q ;
    assign data_o  =  buf2_full_q ?  buf2_q      : buf1_q;
  end
endmodule