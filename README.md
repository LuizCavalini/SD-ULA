# SD-ULA

Arithmetic Logic Unit implemented in VHDL for the EEL480 Digital Systems
course at UFRJ, with a testbench for simulation.

## What it does

The ALU is the combinational block that performs arithmetic and logic
operations on two operands. A selector input chooses which operation to
apply, and the result is produced along with status flags describing it —
typically zero, carry and overflow.

It is purely combinational: there is no clock and no internal state. The
output depends only on the current inputs, which is what allows it to sit
inside a processor's datapath and produce a result within a single cycle.

## Files

| File | Description |
|---|---|
| `ULA.vhdl` | ALU entity and architecture |
| `testbench.vhdl` | Testbench exercising each operation |

## Operations

| Selector | Operation |
|---|---|
| `000` | Addition |
| `001` | Subtraction |
| `010` | Bitwise AND |
| `011` | Bitwise OR |
| `100` | Bitwise XOR |
| `101` | Bitwise NOT |

*Adjust this table to match the opcodes actually implemented.*

## Simulating

With GHDL:

```bash
ghdl -a ULA.vhdl testbench.vhdl
ghdl -e testbench
ghdl -r testbench --vcd=wave.vcd
gtkwave wave.vcd
```

Or open both files in ModelSim/Quartus and run the testbench directly.

## Stack

VHDL · EEL480 Digital Systems (UFRJ)
