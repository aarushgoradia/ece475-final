`ifndef RISCV_TAGE_V
`define RISCV_TAGE_V

// Top-level TAGE-lite predictor module.
// - Small two-level scheme: baseline table T0 + a tagged table T1.
// - `INDEX_BITS` controls number of entries (2^INDEX_BITS).
module riscv_TAGE #(parameter INDEX_BITS = 8) (
    input  clk,
    input  reset,

    // Read port (prediction): PC for which to predict taken/not-taken
    input  [31:0] pc_read,
    output        predict_taken,

    // Write port (update): resolved branch info
    input         update_en,
    input  [31:0] pc_update,
    input         actual_taken,

    // Debug / external signals to observe/update T1 provider information
    output        provider_out,        // indicates whether T1 provided the prediction
    output [7:0]  t1_idx_out,          // T1 index computed from current PC/GHR (exposed)
    output [7:0]  t1_tag_out,          // tag computed for T1 (exposed)

    // Update controls (driven by outside code to indicate which T1 entry to update)
    input         provider_update,     // whether provider was T1 for the prediction being updated
    input  [7:0]  t1_idx_update,       // index into T1 to update
    input  [7:0]  t1_tag_update,       // tag to write into T1 if allocation happens
    input         predicted_taken_update // what was predicted when the branch was speculatively resolved
);
    integer i;

    // Global history register (GHR): simple 8-bit shift register of recent taken bits
    reg [7:0] ghr;
    localparam NUM_ENTRIES = 1 << INDEX_BITS;

    // Baseline predictor T0's prediction (wire to be used if T1 misses)
    wire t0_predict_taken;
    // Only update T0 when T1 was not the provider for that prediction
    wire t0_update_en = update_en && (provider_update == 1'b0);

    // Instantiate simple 2-bit counter table predictor (T0)
    riscv_T0 riscv_T0 (
        .clk (clk),
        .reset (reset),
        .pc_read (pc_read),
        .predict_taken (t0_predict_taken),
        .update_en (t0_update_en),
        .pc_update (pc_update),
        .actual_taken (actual_taken)
    );

    // T1: tagged table arrays
    reg [2:0] t1_ctr [0:NUM_ENTRIES - 1]; // 3-bit saturating counters for stronger predictions / longer hysteresis
    reg [7:0] t1_tag [0:NUM_ENTRIES - 1]; // tag bits to validate indexed entry
    reg       t1_u   [0:NUM_ENTRIES - 1]; // usefulness bit: used for replacement/allocation decisions

    // Index and tag computation for T1:
    // - Use XOR of GHR and pc bits to mix history into index (simple hashing).
    // - Skip the bottom 2 PC bits (4-byte alignment).
    wire [7:0] t1_index_hash = ghr ^ pc_read[9:2];

    // A rotated version of the GHR is used to compute the tag to reduce aliasing
    wire [7:0] rotated_ghr = {ghr[6:0], ghr[7]};
    // Tag mixes rotated history with higher PC bits
    wire [7:0] tag = rotated_ghr ^ pc_read[17:10];

    // T1 hit occurs when stored tag equals computed tag for the indexed entry
    wire t1_hit = t1_tag[t1_index_hash] == tag;

    // Expose computed index/tag for debug or external update arbitration
    assign t1_idx_out = t1_index_hash;
    assign t1_tag_out = tag;

    // Prediction selection:
    // - If T1 hits, use top bit of its 3-bit counter (stronger predictor)
    // - Otherwise fall back to T0's 2-bit counter prediction
    assign predict_taken = t1_hit ? t1_ctr[t1_index_hash][2] : t0_predict_taken;
    assign provider_out = t1_hit ? 1 : 0;

    // Sequential update logic: reset initialization and update on branch resolution
    always @ ( posedge clk ) begin
        if ( reset ) begin
            // Clear GHR and initialize T1 arrays to weakly-not-taken / zero tags
            ghr <= 8'b0;
            for ( i = 0; i < NUM_ENTRIES; i = i + 1 ) begin
                t1_ctr[i] <= 3'b011;  // initialize to weakly not-taken
                t1_tag[i] <= 8'b0;
                t1_u[i]   <= 0;       // usefulness starts cleared
            end
        end
        else if ( update_en ) begin
            // Shift in the actual outcome into the GHR
            ghr <= {ghr[6:0], actual_taken};

            // Update behavior depends on whether the prediction matched the actual outcome
            if (predicted_taken_update == actual_taken) begin
                // Correct prediction case: strengthen counters and mark usefulness if provider was T1
                if (provider_update == 1'b1) begin
                    // Saturating increment if actual was taken; saturating decrement if not
                    if (actual_taken) begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b111 ? 3'b111 : t1_ctr[t1_idx_update] + 1'b1;
                    end
                    else begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b000 ? 3'b000 : t1_ctr[t1_idx_update] - 1'b1;
                    end
                    // Mark entry as useful since it provided a correct prediction
                    t1_u[t1_idx_update] <= 1'b1;
                end
            end
            else begin
                // Misprediction case: either allocate/update entries or decrement usefulness
                if (provider_update == 1'b0) begin
                    // If T0 was provider but T1 may be candidate for allocation:
                    if (t1_u[t1_idx_update]) begin
                        // If usefulness is set, first clear it instead of allocating — replacement policy simplification
                        t1_u[t1_idx_update] <= 0;
                    end
                    else begin
                        // Allocate/overwrite the T1 entry: store tag and set counter to weakly taken or not
                        t1_tag[t1_idx_update] <= t1_tag_update;
                        t1_ctr[t1_idx_update] <= actual_taken ? 3'b100 : 3'b011;
                    end
                end
                else begin
                    // If T1 was provider but it mispredicted: clear usefulness and adjust counter toward actual
                    t1_u[t1_idx_update] <= 0;
                    if (actual_taken) begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b111 ? 3'b111 : t1_ctr[t1_idx_update] + 1'b1;
                    end
                    else begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b000 ? 3'b000 : t1_ctr[t1_idx_update] - 1'b1;
                    end
                end
            end
        end
    end

endmodule

// Simple baseline predictor T0: array of 2-bit saturating counters indexed by low PC bits
module riscv_T0 #(parameter INDEX_BITS = 8) (
    input  clk,
    input  reset,

    // Read port (prediction)
    input  [31:0] pc_read,
    output        predict_taken,

    // Write port (update)
    input         update_en,
    input  [31:0] pc_update,
    input         actual_taken
);

    localparam NUM_ENTRIES = 1 << INDEX_BITS;

    // Counter table: each entry is a 2-bit saturating counter
    reg [1:0] counters [0:NUM_ENTRIES-1];

    // Index computation
    // Skip bottom 2 bits because instructions are 4-byte aligned.
    wire [INDEX_BITS-1:0] read_idx   = pc_read[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] update_idx = pc_update[INDEX_BITS+1:2];

    // Combinational prediction read: use MSB of 2-bit counter to represent taken/not-taken
    assign predict_taken = counters[read_idx][1];

    // Prepare update: compute next saturating counter value based on actual outcome
    wire [1:0] current_ctr = counters[update_idx];

    wire [1:0] next_ctr
        = ( actual_taken && current_ctr != 2'b11 ) ? current_ctr + 2'b01
        : (!actual_taken && current_ctr != 2'b00 ) ? current_ctr - 2'b01
        :                                            current_ctr;

    integer i;

    // Initialize table on reset and apply updates on update_en
    always @ ( posedge clk ) begin
        if ( reset ) begin
            for ( i = 0; i < NUM_ENTRIES; i = i + 1 ) begin
                counters[i] <= 2'b01;  // weakly not-taken initial state
            end
        end
        else if ( update_en ) begin
            counters[update_idx] <= next_ctr; // atomic update of indexed counter
        end
    end

endmodule

`endif
// vim: set textwidth=0 ts=2 sw=2 sts=2 :


