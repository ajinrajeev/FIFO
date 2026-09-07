# FIFO Designs in Verilog

Two FIFO implementations, written in Verilog and verified in
simulation with Icarus Verilog:

| Project | Clock domains | Key technique |
|---|---|---|
| [`synchronous_fifo/`](synchronous_fifo) | Single shared `clk` | Phase-bit pointer comparison |
| [`asynchronous_fifo/`](asynchronous_fifo) | Independent `wclk` / `rclk` | Gray-coded pointers + dual-flop synchronizers |

Each subfolder is self-contained with its own README covering the design in
detail — this page just introduces both and explains how they relate.

## Synchronous vs. asynchronous — why two designs

A FIFO decouples a producer and a consumer through a shared buffer.
When both sides run on the **same clock**, comparing the write and
read pointers to derive FULL/EMPTY is straightforward — see
[`synchronous_fifo`](synchronous_fifo).

When the write and read sides run on **independent clocks** with no
fixed phase relationship (the common case at real clock-domain
boundaries — e.g. a peripheral running at one frequency feeding data
into a processor running at another), a pointer produced in one clock
domain can't be safely sampled directly by the other: a synchronizing
flip-flop can catch a signal mid-transition and resolve to a
completely wrong value if multiple bits are changing at once. Solving
this correctly is the entire point of
[`asynchronous_fifo`](asynchronous_fifo), which uses Gray-coded
pointers (only one bit changes per increment) and two-flop
synchronizers to cross that boundary safely.
