`timescale 1ns / 1ps

module tb_fifo;

    reg clk, rst_n, wr_en, rd_en;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full, empty;

    sync_fifo uut (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .rd_en    (rd_en),
        .data_in  (data_in),
        .data_out (data_out),
        .full     (full),
        .empty    (empty)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // GTKWave dump
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, tb_fifo);

        // Reset
        rst_n   = 0;
        wr_en   = 0;
        rd_en   = 0;
        data_in = 0;

        #10 rst_n = 1;

        // Write 4 values
        repeat (4) begin
            @(negedge clk);
            wr_en   = 1;
            data_in = $random;
        end

        @(negedge clk);
        wr_en = 0;

        // Read 4 values
        repeat (4) begin
            @(negedge clk);
            rd_en = 1;
        end

        @(negedge clk);
        rd_en = 0;

        #20 $finish;
    end

endmodule
