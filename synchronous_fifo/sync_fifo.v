module sync_fifo #(parameter DEPTH = 8, DATA_WIDTH = 8)(
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output full,
    output empty
);

localparam PTR_W = $clog2(DEPTH);
integer i;
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [PTR_W-1:0] w_ptr, r_ptr;  
reg w_phase, r_phase;            

assign full  = (w_ptr == r_ptr) && (w_phase != r_phase);
assign empty = (w_ptr == r_ptr) && (w_phase == r_phase);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_ptr   <= 0;
        r_ptr   <= 0;
        w_phase <= 0;
        r_phase <= 0;
        data_out <= 0;
        for(i = 0;i < DEPTH;i = i + 1)begin
            mem[i] <= 0;
        end
    end
    else begin
        if (wr_en && !full) begin
            mem[w_ptr] <= data_in;
            if (w_ptr == DEPTH-1) begin
                w_ptr   <= 0;
                w_phase <= ~w_phase;
            end else begin
                w_ptr <= w_ptr + 1;
            end
        end
        if (rd_en && !empty) begin
            data_out <= mem[r_ptr];
            if (r_ptr == DEPTH-1) begin
                r_ptr   <= 0;
                r_phase <= ~r_phase;
            end else begin
                r_ptr <= r_ptr + 1;
            end
        end
    end
end

endmodule