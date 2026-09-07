module rptr_handler #(parameter width = 3)
(
    input                  rclk,
    input                  rrst_n,
    input                  r_ena,
    input      [width:0]   wptr_sync,   // synced Gray write pointer
    output reg [width:0]   g_rrpt,
    output reg [width:0]   b_rrpt,
    output reg             empty
);

    wire [width:0] b_rrpt_next;
    wire [width:0] g_rrpt_next;
    wire           rempty;

    assign b_rrpt_next = b_rrpt + (r_ena & !empty);        // gated by !empty
    assign g_rrpt_next = (b_rrpt_next >> 1) ^ b_rrpt_next; // binary -> gray

    // EMPTY: next gray read ptr == synced write ptr (exact match)
    assign rempty = (g_rrpt_next == wptr_sync);

    // pointer registers
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            b_rrpt <= 0;
            g_rrpt <= 0;
        end else begin
            b_rrpt <= b_rrpt_next;
            g_rrpt <= g_rrpt_next;
        end
    end

    // empty flag register
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) empty <= 1'b1;   // FIFO starts EMPTY
        else         empty <= rempty;
    end
endmodule
