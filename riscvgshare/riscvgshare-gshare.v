//=========================================================================
// gShare Branch Predictor
//=========================================================================
// Global History Register (GHR) XORed with PC to index a Pattern History
// Table (PHT) of 2-bit saturating counters.

`ifndef RISCV_GSHARE_V
`define RISCV_GSHARE_V

module riscv_BHT
#(
  parameter GHR_BITS = 10  // also determines PHT size: 2^GHR_BITS entries
)
(
  input                     clk,
  input                     reset,

  // Read port (prediction)
  input      [31:0]         pc_read,
  output                    predict_taken,

  // Write port (update on branch resolution)
  input                     update_en,
  input      [31:0]         pc_update,
  input                     actual_taken
);

  localparam NUM_ENTRIES = 1 << GHR_BITS;

  // Pattern History Table and Global History Register
  reg [1:0]          pht [0:NUM_ENTRIES-1];
  reg [GHR_BITS-1:0] ghr;

  // Index computation (gShare: XOR of PC and GHR)
  wire [GHR_BITS-1:0] read_idx   = pc_read  [GHR_BITS+1:2] ^ ghr;
  wire [GHR_BITS-1:0] update_idx = pc_update[GHR_BITS+1:2] ^ ghr;


  // Prediction (combinational read)
  assign predict_taken = pht[read_idx][1];

  // Update logic (saturating counter)
  wire [1:0] current_ctr = pht[update_idx];

  wire [1:0] next_ctr
    = ( actual_taken && current_ctr != 2'b11 ) ? current_ctr + 2'b01
    : (!actual_taken && current_ctr != 2'b00 ) ? current_ctr - 2'b01
    :                                            current_ctr;


  // Sequential logic: reset, counter update, GHR shift
  integer i;

  always @ ( posedge clk ) begin
    if ( reset ) begin
      for ( i = 0; i < NUM_ENTRIES; i = i + 1 ) begin
        pht[i] <= 2'b01;   // weakly not-taken
      end
      ghr <= {GHR_BITS{1'b0}};
    end
    else if ( update_en ) begin
      pht[update_idx] <= next_ctr;
      ghr <= { ghr[GHR_BITS-2:0], actual_taken };  // shift left, new bit in LSB
    end
  end

endmodule

`endif
// vim: set textwidth=0 ts=2 sw=2 sts=2 :