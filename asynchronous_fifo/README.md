# Asynchronous FIFO (Verilog)

A parameterizable asynchronous (dual-clock) FIFO, written in Verilog and
verified in simulation with Icarus Verilog. Implements the standard
Gray-code / dual-flop-synchronizer architecture (Cummings' technique)
for safely crossing FULL/EMPTY pointer comparisons between two
unrelated clock domains.

## Why an async FIFO is non-trivial

When the write and read sides run on **independent clocks** with no
fixed phase relationship, a multi-bit pointer produced in one domain
cannot be safely sampled directly by the other — a synchronizing
flip-flop can catch a signal mid-transition and go metastable, and if
multiple bits are changing at once (as in an ordinary binary counter),
the value it resolves to can be complete garbage rather than the old
or new value.

This design solves that with two techniques used together:

1. **Gray-coded pointers** — only one bit changes per increment, so a
   synchronizer can never resolve to anything other than the old or
   new value, even in the worst case.
2. **Two-flop synchronizers** — give a metastable signal a full clock
   period to resolve to a stable 0/1 before it reaches any logic.

## Architecture

```
        WRITE CLOCK DOMAIN                     READ CLOCK DOMAIN
    ┌─────────────────────┐               ┌─────────────────────┐
    │   wptr_handler        │              │   rptr_handler         │
    │   - binary + gray wptr │             │   - binary + gray rptr  │
    │   - FULL flag          │             │   - EMPTY flag          │
    └──────────┬───────────┘               └───────────┬───────────┘
               │ g_wptr                                 │ g_rptr
               ▼                                        ▼
        synchronizer (2-flop,                    synchronizer (2-flop,
        clocked by rclk)                         clocked by wclk)
               │                                        │
               ▼                                        ▼
      g_wptr_sync → rptr_handler              g_rptr_sync → wptr_handler
                     (EMPTY calc)                          (FULL calc)

                    both write and read pointers
                    also address a shared dual-port RAM (mem.v)
```

### Pointer width

Every pointer (binary and Gray, local and synchronized) is `ADDR_WIDTH
+ 1` bits wide. The extra MSB — the "wrap bit" — is what makes FULL
and EMPTY distinguishable: without it, a completely full FIFO and a
completely empty FIFO produce identical lower-address bits and can't
be told apart. Only when indexing into the RAM array is a pointer
sliced down to the lower `ADDR_WIDTH` bits.

## Repo layout

```
  synchronizer.v       2-flop CDC synchronizer
  wptr_handler.v       write pointer + FULL flag (write clock domain)
  rptr_handler.v       read pointer + EMPTY flag (read clock domain)
  mem.v                dual-port RAM (shared storage)
  async_fifo_top.v     top-level module wiring everything together
  async_fifo_tb.v      testbench: two independent clocks, write/read
                       bursts, FIFO-order check, full/empty monitors
  waveform.png         example simulation waveform in gtkwave

```





