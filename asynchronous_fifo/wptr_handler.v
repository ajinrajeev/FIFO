module wptr_handler #(parameter width = 3)
(
    input                  wclk,
    input                  wrst_n,
    input                  wr_ena,
    input      [width:0]   rptr_sync,   // synced Gray read pointer
    output reg [width:0]   g_wrpt,
    output reg [width:0]   b_wrpt,
    output reg             full
);

    wire [width:0] b_wrpt_next;
    wire [width:0] g_wrpt_next;
    wire           wfull;

    assign b_wrpt_next = b_wrpt + (wr_ena & !full);        // gated by !full
    assign g_wrpt_next = (b_wrpt_next >> 1) ^ b_wrpt_next; // binary -> gray

    // FULL: next gray write ptr == synced read ptr with top 2 bits inverted
    // (classic Gray-code identity - only valid when both sides are Gray)
    assign wfull = (g_wrpt_next == {~rptr_sync[width:width-1],
                                       rptr_sync[width-2:0]});

    // pointer registers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            b_wrpt <= 0;
            g_wrpt <= 0;
        end else begin
            b_wrpt <= b_wrpt_next;
            g_wrpt <= g_wrpt_next;
        end
    end

    // full flag register
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) full <= 1'b0;   // FIFO starts NOT full
        else         full <= wfull;
    end
endmodule
