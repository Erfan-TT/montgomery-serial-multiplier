# Bit-Serial Montgomery Multiplier — VHDL

A hardware implementation of a **bit-serial Montgomery modular multiplier**
written in VHDL, using a structured **Control Path / Data Path (FSMD)**
methodology. The design targets a generic `WIDTH`-bit operand and provides
**two datapath architectures** that are functionally identical but differ in
how arithmetic is expressed, making them suitable for a direct synthesis
comparison.

---

## Table of Contents

- [Overview](#overview)
- [Algorithm](#algorithm)
- [Architecture](#architecture)
- [Two Datapath Architectures](#two-datapath-architectures)
- [File Structure](#file-structure)
- [Generics and Ports](#generics-and-ports)
- [How to Simulate](#how-to-simulate)
- [Design Decisions](#design-decisions)
- [Known Limitations](#known-limitations)
- [Future Work](#future-work)

---

## Overview

Montgomery modular multiplication computes:

```
MonPro(A, B) = A · B · R⁻¹  mod N
```

where `R = 2ⁿ` and `n` is the operand bit-width. Reduction requires only
additions and right shifts — no division by `N`.

This implementation processes **one bit of B per clock cycle**, making it
area-minimal at the cost of throughput. It is intended as a clean,
well-structured baseline for more advanced architectures.

---

## Algorithm

The iterative REDC loop implemented in hardware:

```
t = 0
for i = 0 to n-1:
    if b_i == 1:  t = t + A
    if t_0 == 1:  t = t + N
    t = t >> 1
if t >= N:  t = t - N
return t
```

The accumulator `t` is sized to `n+3` bits to handle worst-case overflow
(`t + A + N < 4N < 2^(n+2)`, with one guard bit added).

---

## Architecture

The design is split into three entities:

```
montgomery_multiplier        (top level)
├── montgomery_CP            (control path — FSM, shared by both DPs)
└── montgomery_DP            (datapath — choose one of two architectures)
       ├── montgomery_DP_behavioral   (fully behavioral)
       └── montgomery_DP_structural   (structural P4 adder for reduction)
```

### Control Path FSM

```
          start=1
  ┌──── IDLE ────────────────────────────┐
  │   rst_from_cp=1                      │
  ▼                                      │
LOAD  ──(1 cycle)──►  RUN  ──eq=1──►  FINISH
ld=1               sh=1, en_index=1    done=1
```

| State    | Active Signals              | Transition Condition     |
|----------|-----------------------------|--------------------------|
| `IDLE`   | `rst_from_cp`               | `start = '1'` → `LOAD`   |
| `LOAD`   | `ld`, `busy`                | Unconditional → `RUN`    |
| `RUN`    | `sh`, `en_index`, `busy`    | `eq = '1'` → `FINISH`    |
| `FINISH` | `done`, `busy`              | Unconditional → `IDLE`   |

The control path is identical for both datapath variants. The `result` output
is permanently driven combinationally from `result_temp` in both architectures,
so no dedicated result-latch state is required.

---

## Two Datapath Architectures

The key design question this project investigates is whether explicitly
instantiating a fast adder structure for the final reduction step
(`t - N`) produces measurably better synthesis results compared to letting
the synthesiser infer its own carry-chain logic from behavioral code.

### `montgomery_DP_behavioral` — Fully Behavioral

All arithmetic — the two accumulation steps (`t + A`, `t + N`) and the
final reduction (`t - N`) — is written in behavioral VHDL using standard
`+` and `>=` operators. The synthesiser maps everything to carry-chain
primitives automatically.

```vhdl
-- Reduction expressed behaviorally
if temp >= N_reg then 
    result_temp <= resize((temp - resize(N_reg, temp'length)), WIDTH); 
else 
    result_temp <= resize(temp, WIDTH);
end if;
```

**Expected characteristics:** consistent abstraction level throughout,
smallest and most predictable RTL, synthesis result fully determined by
tool optimisation settings.

### `montgomery_DP_structural` — Structural P4 Adder for Reduction

The accumulation steps remain behavioral, but the final reduction (`t - N`)
is handled by an explicitly instantiated **Parallel-Prefix Carry-Lookahead
(P4) adder**. The subtraction is computed as `t + ~N + 1` (two's complement),
and the carry-out `cout` acts as the comparison flag (`cout = 1 ⟺ t ≥ N`)
for free.

```vhdl
-- P4 adder always computes t - N combinationally
p4adder: P4_ADDER generic map(NBIT => WIDTH+3)
    port map(A => std_logic_vector(t_reg_next), B => negated_N,
             Cin => '1', S => t_subtracted, Cout => cout);

-- MUX selects result combinationally
if cout = '1' then
    result_temp <= resize(unsigned(t_subtracted), WIDTH);
else
    result_temp <= resize(t_reg_next, WIDTH);
end if;
```

**Expected characteristics:** explicit control over the reduction adder
topology, but mixed abstraction level (behavioral accumulation + structural
reduction). Whether this actually improves timing over the fully behavioral
version is an open question — the synthesiser may produce equivalent
structures from behavioral code anyway.

### Open Question: Which is Better?

For a bit-serial multiplier, the area argument slightly favours the
behavioral version:

- A Parallel-Prefix adder costs `O(n log n)` gates vs `O(n)` for a
  ripple-carry adder.
- The throughput of the design does not change regardless of adder choice —
  it is always `n + 4` cycles.
- The clock frequency might improve with the P4 adder if the reduction step
  is the critical path, but this is **unverified without a timing report**.
- Whether the reduction is even the critical path at all is unknown — the
  chained `t + A` / `t + N` accumulation in the same combinational process
  may dominate instead.

The honest answer is that the right choice depends on synthesis results,
which is exactly what the next phase of this project investigates.

| Architecture        | Abstraction | Area (expected) | Timing (expected)                             |
|---------------------|-------------|-----------------|-----------------------------------------------|
| Fully behavioral    | Consistent  | Smaller         | Tool-determined                               |
| Structural P4 adder | Mixed       | Larger          | Better only if reduction is the critical path |

---

## File Structure

```
/
├── src/
│   ├── montgomery_multiplier.vhd      # Top-level entity
│   ├── montgomery_CP.vhd              # Control path FSM (shared)
│   ├── montgomery_DP_behavioral.vhd   # Datapath — fully behavioral
│   ├── montgomery_DP_structural.vhd   # Datapath — structural P4 adder
│   └── P4_ADDER.vhd                   # Parallel-prefix adder component
├── tb/
│   └── tb_montgomery.vhd              # Testbench (works with both DPs)
├── docs/
│   ├── montgomery_report.pdf          # Full design report
│   └── figures/
│       ├── control_path.png
│       ├── datapath.png
│       └── p4_adder.png
└── README.md
```

To switch between architectures, change the component instantiation in
`montgomery_multiplier.vhd` and recompile. Both datapaths expose identical
ports so no other changes are required.

---

## Generics and Ports

### Top-Level: `montgomery_multiplier`

| Generic | Default | Description          |
|---------|---------|----------------------|
| `WIDTH` | 32      | Operand bit-width    |

| Port     | Direction | Width     | Description                         |
|----------|-----------|-----------|-------------------------------------|
| `clk`    | in        | 1 bit     | System clock                        |
| `rst`    | in        | 1 bit     | Asynchronous active-high reset      |
| `start`  | in        | 1 bit     | Assert for one cycle to begin       |
| `A`      | in        | WIDTH     | First operand                       |
| `B`      | in        | WIDTH     | Second operand                      |
| `N`      | in        | WIDTH     | Modulus (must be odd)               |
| `result` | out       | WIDTH     | Montgomery product output           |
| `busy`   | out       | 1 bit     | High while computation is running   |
| `done`   | out       | 1 bit     | Pulses high for one cycle on finish |

---

## How to Simulate

### Prerequisites

- [GHDL](https://github.com/ghdl/ghdl) or any VHDL-2008 compatible simulator
- (Optional) [GTKWave](https://gtkwave.sourceforge.net/) for waveform viewing

### With GHDL — Behavioral DP

```bash
ghdl -a --std=08 src/montgomery_CP.vhd
ghdl -a --std=08 src/montgomery_DP_behavioral.vhd
ghdl -a --std=08 src/montgomery_multiplier.vhd
ghdl -a --std=08 tb/tb_montgomery.vhd
ghdl -e --std=08 tb_montgomery
ghdl -r --std=08 tb_montgomery --vcd=wave_behavioral.vcd
```

### With GHDL — Structural DP

```bash
ghdl -a --std=08 src/P4_ADDER.vhd
ghdl -a --std=08 src/montgomery_CP.vhd
ghdl -a --std=08 src/montgomery_DP_structural.vhd
ghdl -a --std=08 src/montgomery_multiplier.vhd
ghdl -a --std=08 tb/tb_montgomery.vhd
ghdl -e --std=08 tb_montgomery
ghdl -r --std=08 tb_montgomery --vcd=wave_structural.vcd
```

### Verifying Results

```python
# Python reference — compute expected MonPro result
def monpro(A, B, N, n):
    R_inv = pow(2**n, -1, N)
    return (A * B * R_inv) % N

# Example: monpro(5, 7, 13, 8) == 1
```

---

## Design Decisions

**Why bit-serial?**
Processes one bit of B per cycle. Minimal area — suitable for
resource-constrained environments or as a functional baseline before
building higher-performance architectures.

**Why CP/DP separation?**
Follows the standard FSMD methodology. Keeps control logic and arithmetic
cleanly separated, making both easier to verify and modify independently.
Sharing a single control path between two datapath variants also directly
demonstrates the benefit of this separation.

**Why two datapath architectures?**
The structural P4 adder was originally included under the assumption that
the final reduction step is the critical timing path. However this is
unverified — the synthesiser may already infer an equivalent adder from
behavioral code, and for a bit-serial design the area overhead of
`O(n log n)` parallel-prefix logic may outweigh any timing benefit.
Rather than discard the idea, both architectures are preserved so synthesis
results can answer the question empirically.

**Why is `CHECKING_N` state removed?**
The original design latched `result_temp` into `result` via a dedicated
FSM state. Since `result` is now permanently driven combinationally, the
state is unnecessary and was removed, simplifying the FSM to four states.

---

## Known Limitations

- Inputs `A` and `B` must already be in Montgomery domain for the output
  to represent a standard integer.
- `N` must be odd (required by the Montgomery algorithm).
- No input validation — behaviour is undefined if `A ≥ N` or `B ≥ N`.
- Throughput is `1 result per (WIDTH + 4) cycles`.

---

## Future Work

This project is the first in a series, with the following roadmap:

### Immediate — Synthesis Comparison

Run both datapath architectures through synthesis targeting the same device
and compare:

- **Critical path delay** — does the P4 adder improve `Fmax`?
- **LUT / cell count** — what is the area cost of the structural adder?
- **Where the critical path actually lies** — reduction step, or the chained
  `t + A` / `t + N` accumulation?

The results will establish whether structural adder instantiation is
justified for this architecture and inform adder choices in future designs.

### Next — Word-Serial Montgomery Multiplier

Process `k > 1` bits of B per clock cycle, reducing latency to `⌈n/k⌉ + 4`
cycles. Once throughput is an explicit goal, the P4 adder trade-off becomes
more meaningful and better motivated.

### Long-Term — Systolic Array Montgomery Multiplier

A fully pipelined systolic array where `n` identical Processing Elements
(PEs) are connected with only local interconnect. Key properties:

- One result per cycle once the pipeline is filled
- Regular, locally-connected structure — ideal for ASIC layout
- Scales linearly with operand width

This is the architecture used in production cryptographic accelerator cores
and represents the performance target of this project series.

| Project      | Architecture          | Latency (cycles)      | Status      |
|--------------|-----------------------|-----------------------|-------------|
| This project | Bit-serial (×2 DPs)   | `n + 4`               | ✅ Complete |
| Next         | Synthesis comparison  | —                     | 🔲 Planned  |
| Next         | Word-serial (k-bit)   | `⌈n/k⌉ + 4`          | 🔲 Planned  |
| Long-term    | Systolic array        | `n + depth` pipelined | 🔲 Planned  |

---

## References

- P. L. Montgomery, *"Modular Multiplication Without Trial Division"*,
  Mathematics of Computation, vol. 44, no. 170, pp. 519–521, 1985.
- Koc, Acar, Kaliski, *"Analyzing and Comparing Montgomery Multiplication
  Algorithms"*, IEEE Micro, 1996.
