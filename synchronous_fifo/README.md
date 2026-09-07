# Synchronous FIFO (Verilog)

A parameterizable single-clock-domain FIFO, written in Verilog and
verified in simulation with Icarus Verilog.

## Design

Both write and read happen on the same `clk`, so pointers can be
compared directly with no clock-domain-crossing concerns — no Gray
coding, no synchronizers needed.

FULL/EMPTY detection uses a **phase bit** per pointer instead of the
extra-address-bit trick used in the async design: each pointer wraps
from `DEPTH-1` back to `0` and toggles its own phase bit on wrap.

- **EMPTY**: pointers equal, same phase → no unread data
- **FULL**: pointers equal, phases differ → write has lapped read by
  exactly one full pass through the buffer

## Repo layout

```
  sync_fifo.v         FIFO design (RAM + pointer + full/empty logic)
  tb_fifo.v           testbench: reset, write burst, read burst
  waveform.png        example simulation waveform in gtkwave
```

