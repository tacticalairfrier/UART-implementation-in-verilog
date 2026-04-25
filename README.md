# UART — Verilog Implementation

A fully parameterized UART transceiver implemented in Verilog, supporting 8E1 framing (8 data bits, even parity, 1 stop bit) with a loopback testbench. Designed and verified on a Basys 3 (Artix-7) at 100 MHz.

---

## Features

- Parameterized `CLK_FREQ` and `BAUD_RATE` — derived `BAUD_PERIOD` via localparam
- 8E1 framing: 8 data bits, even parity, 1 stop bit
- TX: FSM-based shift register serializer with parity generation
- RX: 16× oversampling with mid-bit sampling and parity verification
- RX flags: `rx_done`, `parity_err`, `error_flag` (framing error)
- Loopback testbench connecting TX output directly to RX input

---

## Architecture

### TX

Five-state Moore FSM: `IDLE → START → DATA → PARITY → STOP`

The design follows strict three-block FSM discipline:

| Block | Type | Responsibility |
|---|---|---|
| Baud tick generator | Clocked | Counts down from `BAUD_PERIOD`, pulses `baud_tick` |
| State register | Clocked | `state <= nextstate` on each `baud_tick` |
| NSL | Combinational | Computes `nextstate`, `shiftregnext` |
| Output logic | Combinational | Drives `data_out` directly from `state` |

`TX_enable` controls the STOP→IDLE vs STOP→START transition, allowing continuous back-to-back transmission when held high.

### RX

Five-state Moore FSM: `IDLE → START → DATA → PARITY → STOP` with an `ERROR_RX` framing error state.

| Block | Type | Responsibility |
|---|---|---|
| Oversample tick generator | Clocked | Counts down from `BAUD_OVERSAMPLE = CLK_FREQ/(BAUD_RATE×16)` |
| State register | Clocked | Transitions on each `samplex16_tick` |
| NSL + Output | Combinational | Computes `nextstate`, sample/data counters, flags |

**Sampling strategy:**

- Edge detection on `rx_prev & ~rx` triggers entry into START
- START waits 8 oversample ticks (SAMPLEX8) to land at the mid-point of the start bit and verify it is still low
- DATA and subsequent states wait 16 ticks (SAMPLEX16) between samples to stay mid-bit
- Parity checked combinationally as `^shiftreg != rx` in PARITY state
- STOP checks `rx == 1`; if low, transitions to `ERROR_RX`

**Bit ordering:** RX samples MSB-first off the wire (big-endian serial) and reconstructs into a little-endian `data_out` byte using `shiftreg[DATCOUNT - data_counter]` indexing.

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `CLK_FREQ` | `100_000_000` | System clock frequency in Hz |
| `BAUD_RATE` | `115200` | Target baud rate |

Derived localparams:

```verilog
localparam BAUD_PERIOD    = CLK_FREQ / BAUD_RATE;       // ~434 at defaults
localparam BAUD_OVERSAMPLE = CLK_FREQ / (BAUD_RATE * 16); // ~27 at defaults
```

### Common baud rates at 50 MHz

| Baud Rate | `BAUD_PERIOD` | `BAUD_OVERSAMPLE` |
|---|---|---|
| 9600 | 5208 | 325 |
| 19200 | 2604 | 162 |
| 57600 | 868 | 54 |
| 115200 | 434 | 27 |
| 230400 | 217 | 13 |
| 921600 | 54 | 3 |

> **Note:** At 921600 baud the oversample divisor drops to 3, giving very little noise margin. 115200 is the recommended maximum for reliable operation at 50 MHz.

---

## File Structure

```
src/
  UART_tx.v       — Transmitter module
  UART_rx.v       — Receiver module
test/
  testbench_rx.v  — Loopback testbench (TX → RX)
  testbench_tx.v  — Standalone TX testbench
images/
  schematic_netlist.pdf  -Generated Netlist Schematic
  schematic_synth.pdf  -Generated Netlist Schematic for synthesyzed design
  schematic_implementation.pdf  -Generated schematic for implemented design
```

---

## Simulation

Using iverilog and GTKWave:

```bash
iverilog -o sim.out src/UART_tx.v src/UART_rx.v test/testbench_rx.v
vvp sim.out
gtkwave sim.vcd
```

The testbench drives `data_tx` with `$urandom_range(0, 255)` at one-frame intervals and routes TX output directly into RX input. `$monitor` prints input/output values on every change — a one-frame skew between `data_tx` and `data_rx` is **expected and correct**, as it represents the serialization latency of one complete 10-bit frame (~86.8 µs at 115200 baud).

---

## Known Limitations

- Reset pulse in testbench is narrower than one clock cycle — functional but not representative of real hardware reset behaviour
- `data_tx` updates on a fixed timer rather than gating on `tx_busy`, so back-to-back frame stress testing is not covered
- No `tx_busy` or `rx_valid` handshake pins yet — planned for next revision

---

## What I Learnt

**Three-block FSM discipline.** The most significant debug session on this project came from accidentally placing output and data-capture logic inside the state register block instead of the NSL/output block. This prevented the FSM from advancing because the state register block should contain *only* `state <= nextstate` (plus reset). The moment anything else is computed there, you break the clean separation between registered state and combinational next-state logic, and simulation behaviour stops matching intent.

**Oversampling and mid-bit sampling.** The RX side doesn't share a clock with the TX side — it reconstructs timing from the data stream itself. Waiting SAMPLEX8 ticks after edge detection before committing to START, then SAMPLEX16 between subsequent samples, keeps all samples near the centre of each bit period where the signal is most stable.

**Combinational output in Moore FSMs.** Driving `data_out` from `state` directly in a combinational block (rather than registering it) removes one cycle of latency from the output and makes the waveform easier to read — the output changes at the same edge as the state transition.

---

## Part of

This module is a building block toward a larger FPGA capstone — a hybrid RV32I soft-core system with RTL hardware accelerators targeting a voxel renderer on an Arty A7-100T.
