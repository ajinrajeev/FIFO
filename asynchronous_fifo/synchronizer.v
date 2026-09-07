module synchronizer #(parameter width = 8)(
    input                  clk,
    input                  rst_n,
    input      [width:0]   din,
    output reg [width:0]   dout
);

    reg [width:0] q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q    <= 0;
            dout <= 0;
        end else begin
            q    <= din;   // flop 1 - may go metastable
            dout <= q;     // flop 2 - resolved, safe to use
        end
    end
endmodule
