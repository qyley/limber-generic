/*----------------------------------------------------------------
| Fractional counter
|
| This counter can generate a Fractional clock frequency division on `overflow_o` output
| Also can be a normal counter with configurable single/periodic triggle mode,
| up/down count mode, max count value and count increment.
|
| This counter add(or minus) an increment value each clock if en_i=1,
  When counter exceed its boundary(the max or 0 for up/down mode), it will
  minus(or add) a max count value to keep counter in the range of [0, max].
| 
| Usage:
| to generate a pulse every 3.2 clock,
  which means counter need accumulate 10/32 or 5/16 every clock.
  by setting max = 15 and inc = 5, this counter can generate 5 `overflow_o` pulse
  every 16 clocks, it's apporximately to a clock frequency division by 3.2
| 
| set max = -1 and inc = 1 make counter be a normal counter
----------------------------------------------------------------*/
module gnrc_fractional_counter #(
  /* The width of the Denominator and Numerator part of a Fractions Expression. @range: ">=1"*/
  parameter int unsigned N  = 8
) (
  /* clock input */
  input logic           clk_i,
  /* asynchronous low-active reset input */
  input logic           rst_ni,
  /* mode select input.
  if mode=0, counter will stop once overflow is assert and hold on until a new clr or ld.
  if mode=1, counter work periodically and overflow will not be hold. */
  input logic           mode_i,
  /* Count up(0) or down(1) */
  input logic           down_i,
  /* load counter configure data(max, inc) */
  input logic           ld_i,
  /* the max of counter's numerator, equivalent to the denominator minus 1 */
  input logic [N-1:0]   max_i,
  /* increment of the numerator */
  input logic [N-1:0]   inc_i,
  /* counter runing iff the en_i=1 */
  input logic           en_i,
  /* synchronous reset the `cnt_o` and `overflow_o` */
  input logic           clr_i,
  /* the fraction numerator part of the counter */
  output logic  [N-1:0] cnt_o,
  /* overflow assert if counter exceed boundary */
  output logic          overflow_o
);

  // Latch the load data
  logic [N-1:0] max_r;
  logic [N-1:0] inc_r;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      max_r <= 'b0;
      inc_r <= 'b0;
    end else begin
      if(ld_i) begin
        max_r <= max_i;
        inc_r <= inc_i;
      end
    end
  end

  logic overflow_r;

  // Fractions Accumulating Counter
  logic [N-1:0] cnt_r;
  // expand one bit to accommodate overflow bit
  logic [N:0] cnt_inc;
  logic [N:0] cnt_inc_overflow;
  logic cnt_overflow;

  assign cnt_inc = down_i ? cnt_r - inc_r : cnt_r + inc_r;
  assign cnt_inc_overflow = down_i ? cnt_r - inc_r + max_r : cnt_r + inc_r - max_r;
  assign cnt_overflow = cnt_inc > max_r;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      cnt_r <= 'b0;
    end else begin
      if(ld_i|clr_i) begin
        if(down_i)begin
          cnt_r <= max_r;
        end else begin
          cnt_r <= 'b0;
        end
      end else if(mode_i|~overflow_r) begin
        if(en_i) begin
          if(cnt_overflow) begin
            cnt_r <= cnt_inc_overflow;
          end else begin
            cnt_r <= cnt_inc;
          end
        end
      end
    end
  end
  
  // overflow output

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      overflow_r <= 'b0;
    end else begin
      if(ld_i|clr_i) begin
        overflow_r <= 'b0;
      end else if(mode_i|~overflow_r) begin
        if(en_i) begin
          if(cnt_overflow) begin
            overflow_r <= 'b1;
          end else begin
            overflow_r <= 'b0;
          end
        end else begin
          overflow_r <= 'b0;
        end
      end
    end
  end

  assign cnt_o = cnt_r;
  assign overflow_o = overflow_r;

endmodule