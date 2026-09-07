`include "synchronizer.v"
`include "wptr_handler.v"
`include "rptr_handler.v"
`include "mem.v"
module asynchronous_fifo #(parameter depth = 8, data_width = 8) (
    input                        wclk, wrst_n,
    input                        rclk, rrst_n,
    input                        w_en, r_en,
    input      [data_width-1:0]  data_in,
    output     [data_width-1:0]  data_out,
    output                       full, empty
);

    localparam width = $clog2(depth);   // ADDR_WIDTH

    wire [width:0] g_wptr, b_wptr;
    wire [width:0] g_rptr, b_rptr;
    wire [width:0] g_wptr_sync, g_rptr_sync;

    // write pointer (gray) synced into read clock domain
    synchronizer #(width) sync_wptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (g_wptr),
        .dout  (g_wptr_sync)
    );

    // read pointer (gray) synced into write clock domain
    synchronizer #(width) sync_rptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (g_rptr),
        .dout  (g_rptr_sync)
    );

    wptr_handler #(width) wptr_h (
        .wclk      (wclk),
        .wrst_n    (wrst_n),
        .wr_ena    (w_en),
        .rptr_sync (g_rptr_sync),
        .g_wrpt    (g_wptr),
        .b_wrpt    (b_wptr),
        .full      (full)
    );

    rptr_handler #(width) rptr_h (
        .rclk      (rclk),
        .rrst_n    (rrst_n),
        .r_ena     (r_en),
        .wptr_sync (g_wptr_sync),
        .g_rrpt    (g_rptr),
        .b_rrpt    (b_rptr),
        .empty     (empty)
    );

    mem #(width, depth, data_width) fifo_mem (
        .wclk     (wclk),
        .w_en     (w_en),
        .rclk     (rclk),
        .r_en     (r_en),
        .b_wptr   (b_wptr),
        .b_rptr   (b_rptr),
        .data_in  (data_in),
        .full     (full),
        .empty    (empty),
        .data_out (data_out)
    );

endmodule
