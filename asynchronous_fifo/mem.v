module mem #(parameter width = 3, depth = 8, data_width = 8)(
    input                        wclk, w_en, rclk, r_en,
    input      [width:0]         b_wptr, b_rptr,
    input      [data_width-1:0]  data_in,
    input                        full, empty,
    output reg [data_width-1:0]  data_out
);

    reg [data_width-1:0] fifo [0:depth-1];

    always @(posedge wclk) begin
        if (w_en & !full) begin
            fifo[b_wptr[width-1:0]] <= data_in;
        end
    end

    always @(posedge rclk) begin
        if (r_en & !empty) begin
            data_out <= fifo[b_rptr[width-1:0]];
        end
    end
endmodule
