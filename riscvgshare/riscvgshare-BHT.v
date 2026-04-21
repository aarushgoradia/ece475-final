`ifndef RISCV_BHT_V
`define RISCV_BHT_V


module riscv_BHT #(parameter INDEX_BITS = 10) (
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


