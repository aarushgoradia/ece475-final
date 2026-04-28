`ifndef RISCV_TAGE_V
`define RISCV_TAGE_V


module riscv_TAGE #(parameter INDEX_BITS = 8) (
    input  clk,
    input  reset,

    // Read port (prediction)
    input  [31:0] pc_read,
    output        predict_taken,

    // Write port (update)
    input         update_en,
    input  [31:0] pc_update,
    input         actual_taken,

    output        provider_out,
    output [7:0]  t1_idx_out,
    output [7:0]  t1_tag_out,

    input         provider_update,
    input  [7:0]  t1_idx_update,
    input  [7:0]  t1_tag_update,
    input         predicted_taken_update

);
    integer i;
    
    reg [7:0] ghr;
    localparam NUM_ENTRIES = 1 << INDEX_BITS;

    wire t0_predict_taken;
    wire t0_update_en = update_en && (provider_update == 1'b0);

    riscv_T0 riscv_T0 (
        .clk (clk),
        .reset (reset),
        .pc_read (pc_read),
        .predict_taken (t0_predict_taken),
        .update_en (t0_update_en),
        .pc_update (pc_update),
        .actual_taken (actual_taken)
    );

    reg [2:0] t1_ctr [0:NUM_ENTRIES - 1];
    reg [7:0] t1_tag [0:NUM_ENTRIES - 1];
    reg         t1_u [0:NUM_ENTRIES - 1];

    wire [7:0] t1_index_hash = ghr ^ pc_read[9:2];
    wire [7:0] rotated_ghr = {ghr[6:0], ghr[7]};
    wire [7:0] tag = rotated_ghr ^ pc_read[9:2];

    wire t1_hit = t1_tag[t1_index_hash] == tag;

    assign t1_idx_out = t1_index_hash;
    assign t1_tag_out = tag;
    assign predict_taken = t1_hit ? t1_ctr[t1_index_hash][2] : t0_predict_taken;
    assign provider_out = t1_hit ? 1 : 0;

    always @ ( posedge clk ) begin
        if ( reset ) begin
            ghr <= 8'b0;
            for ( i = 0; i < NUM_ENTRIES; i = i + 1 ) begin
                t1_ctr[i] <= 3'b011;  // weakly not-taken (matches baseline prior)
                t1_tag[i] <= 8'b0;
                t1_u[i] <= 0;
            end
        end
        else if ( update_en ) begin
            ghr <= {ghr[6:0], actual_taken};
            if (predicted_taken_update == actual_taken) begin
                if (provider_update == 1'b1) begin
                    if (actual_taken) begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b111 ? 3'b111 : t1_ctr[t1_idx_update] + 1'b1;
                    end
                    else begin
                        t1_ctr[t1_idx_update] <= t1_ctr[t1_idx_update] == 3'b000 ? 3'b000 : t1_ctr[t1_idx_update] - 1'b1;
                    end
                    t1_u[t1_idx_update] <= 1'b1;
                end
            end
            else begin
                if (provider_update == 1'b0) begin
                    if (t1_u[t1_idx_update]) begin
                        t1_u[t1_idx_update] <= 0;
                    end
                    else begin
                        t1_tag[t1_idx_update] <= t1_tag_update;
                        t1_ctr[t1_idx_update] <= actual_taken ? 3'b100 : 3'b011;
                    end
                end
                else begin
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

    // Counter table
    reg [1:0] counters [0:NUM_ENTRIES-1];

    // Index computation
    // Skip bottom 2 bits (instructions are 4-byte aligned in RISC-V)

    wire [INDEX_BITS-1:0] read_idx   = pc_read[INDEX_BITS+1:2];
    wire [INDEX_BITS-1:0] update_idx = pc_update[INDEX_BITS+1:2];

    // Prediction (combinational read)
    assign predict_taken = counters[read_idx][1];

    // Update logic (saturating counter)
    wire [1:0] current_ctr = counters[update_idx];

    wire [1:0] next_ctr
        = ( actual_taken && current_ctr != 2'b11 ) ? current_ctr + 2'b01
        : (!actual_taken && current_ctr != 2'b00 ) ? current_ctr - 2'b01
        :                                            current_ctr;

    // Sequential logic: initialize on reset, update on branch resolution
    integer i;

    always @ ( posedge clk ) begin
        if ( reset ) begin
        for ( i = 0; i < NUM_ENTRIES; i = i + 1 ) begin
            counters[i] <= 2'b01;  // weakly not-taken (matches baseline prior)
        end
        end
        else if ( update_en ) begin
        counters[update_idx] <= next_ctr;
        end
    end

    endmodule

    `endif
    // vim: set textwidth=0 ts=2 sw=2 sts=2 :


