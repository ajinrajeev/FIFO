`timescale 1ns/1ps

module async_fifo_tb;

    localparam DEPTH      = 8;
    localparam DATA_WIDTH = 8;

    reg                     wclk, wrst_n;
    reg                     rclk, rrst_n;
    reg                     w_en, r_en;
    reg  [DATA_WIDTH-1:0]   data_in;
    wire [DATA_WIDTH-1:0]   data_out;
    wire                    full, empty;

    integer wr_count;
    integer rd_count;
    integer wi;   // write-process loop variable (separate from read's, since
    integer ri;   // both initial blocks run concurrently - sharing one variable
                  // between them was a real bug: each process stomped on the
                  // other's loop counter mid-run)
    reg [DATA_WIDTH-1:0] expected;      // used by the comparison check
    reg [DATA_WIDTH-1:0] expected_disp; // purely cosmetic: mirrors `expected`
                                         // but updates on the SAME rclk edge
                                         // as data_out, so the two traces line
                                         // up visually in the waveform viewer.
                                         // Has no effect on the pass/fail check.

    asynchronous_fifo #(.depth(DEPTH), .data_width(DATA_WIDTH)) DUT (
        .wclk     (wclk),
        .wrst_n   (wrst_n),
        .rclk     (rclk),
        .rrst_n   (rrst_n),
        .w_en     (w_en),
        .r_en     (r_en),
        .data_in  (data_in),
        .data_out (data_out),
        .full     (full),
        .empty    (empty)
    );

    //-----------------------------------------------------------------
    // Independent clocks - different periods, no common phase.
    //-----------------------------------------------------------------
    initial wclk = 0;
    always #5  wclk = ~wclk;   // 10ns period -> 100MHz

    initial rclk = 0;
    always #7  rclk = ~rclk;   // 14ns period -> ~71MHz

    //-----------------------------------------------------------------
    // Reset
    //-----------------------------------------------------------------
    initial begin
        wrst_n   = 0;
        rrst_n   = 0;
        w_en     = 0;
        r_en     = 0;
        data_in  = 0;
        wr_count = 0;
        rd_count = 0;
        expected = 0;

        #20;
        wrst_n = 1;
        rrst_n = 1;
    end

    //-----------------------------------------------------------------
    // Write process: push DEPTH+2 words (more than depth, to prove
    // `full` actually blocks writes and nothing overflows/corrupts).
    //-----------------------------------------------------------------
    initial begin
        wait (wrst_n == 1);
        @(posedge wclk);

        for (wi = 0; wi < DEPTH + 2; wi = wi + 1) begin
            @(posedge wclk);
            while (full) @(posedge wclk);      // stall while full
            w_en    <= 1;
            data_in <= wi;
            @(posedge wclk);
            w_en    <= 0;
            wr_count = wr_count + 1;
        end

        $display("[%0t] WRITE: pushed %0d words", $time, wr_count);
    end

    //-----------------------------------------------------------------
    // Read process: starts a bit later, drains everything written,
    // verifying FIFO order (first word in must be first word out).
    //-----------------------------------------------------------------
    initial begin
        wait (rrst_n == 1);
        #50;   // let a few writes accumulate first

        for (ri = 0; ri < DEPTH + 2; ri = ri + 1) begin
            @(posedge rclk);
            while (empty) @(posedge rclk);     // stall while empty
            r_en <= 1;
            @(posedge rclk);                   // edge where data_out updates
            r_en <= 0;
            #1;                                 // let data_out settle post-edge
            if (data_out !== expected)
                $display("[%0t] MISMATCH: expected %0d, got %0d",
                          $time, expected, data_out);
            else
                $display("[%0t] READ OK: got %0d", $time, data_out);
            rd_count = rd_count + 1;
            expected = expected + 1;
        end
    end

    //-----------------------------------------------------------------
    // Cosmetic-only: expected_disp changes on the exact same rclk edge
    // that data_out changes (i.e. when r_en was high on the prior edge),
    // so the two traces overlay cleanly in a waveform viewer. This plays
    // no role in the actual pass/fail check above.
    //-----------------------------------------------------------------
    initial expected_disp = 0;
    always @(posedge rclk) begin
        if (r_en) expected_disp <= expected_disp + 1;
    end

    //-----------------------------------------------------------------
    // Flag monitors
    //-----------------------------------------------------------------
    always @(posedge full)  $display("[%0t] FULL asserted",   $time);
    always @(negedge full)  $display("[%0t] FULL deasserted",  $time);
    always @(posedge empty) $display("[%0t] EMPTY asserted",   $time);
    always @(negedge empty) $display("[%0t] EMPTY deasserted", $time);

    //-----------------------------------------------------------------
    // Finish
    //-----------------------------------------------------------------
    initial begin
        #2000;
        $display("Simulation done. wr_count=%0d rd_count=%0d", wr_count, rd_count);
        $finish;
    end

    //-----------------------------------------------------------------
    // Waveform dump
    //-----------------------------------------------------------------
    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);
    end

endmodule
