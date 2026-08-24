# MOPA pulse width is `M39P<ns>` — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **Lens:** Red · **Source:** MOPA
**Contributor:** Lee Gillie

> **This is the project's central result.** Two real MOPA jobs, identical except for the pulse
> width setting in MakeIt. The captured G-code differs by exactly one line.

## The diff

```diff
- M39P200        # job run at pulse width 200
+ M39P500        # job run at pulse width 500
```

**Nothing else changed.** Not one other byte of the preamble:

```gcode
;wecreat 3.0.6
;canvas border: 0 0 210 210
M15S1  M107X-105Y-105  M57A450B30  M19S0  M18S0
G90  G4P1  M46A1B0  G0X105Y105
M25S1  M26S1  M24S15  M15S70  M59A-1000B50
M1S0  M4S1000  M11S0.08
M38F48         <- unchanged (frequency was not altered)
M39P200 / P500 <- THE ONLY DIFFERENCE
G0F15000  G1F12000
```

## Conclusions

| Finding | Grade |
|---|---|
| **`M39P<n>` sets the MOPA pulse width.** The value tracks MakeIt's pulse-width setting exactly, 1:1 | **CONFIRMED-vendor** |
| **`M38F<n>` sets the MOPA frequency.** Confirmed by its own differential — see below | **CONFIRMED-vendor** |
| `M46` | `A1B0` here vs `A0.9764B20` in the earlier job — job-dependent, still UNKNOWN |
| Also newly seen | `M5` (laser off), `M6` (job end — matches the Vision `EndGCode`), `M9` (coolant off). All standard GRBL |

## Why this matters — the MOPA wall is down

[`docs/09-k9-and-mopa-limits.md`](../docs/09-k9-and-mopa-limits.md) documented this as the sharp
edge of the whole project: LightBurn exposes **Q-Pulse Width** and **Frequency** only on
galvo-class devices, and the Lumos Ultra is a GRBL-class device to LightBurn. So the reason to
own a MOPA — independently controllable pulse width and repetition rate — appeared unreachable.

**It is reachable.** Both parameters are plain G-code:

```gcode
M38F<kHz>     ; frequency
M39P<ns>      ; pulse width
```

LightBurn's GRBL device class supports **per-layer custom G-code**. So each layer in a job can
carry its own `M38`/`M39` pair, which is exactly the granularity a MOPA material library needs.
It is not as elegant as native fields, but it is real, per-layer parameter control.

**Practical consequence:** a LightBurn material library for the Ultra's MOPA can be built —
different pulse widths for colour marking on stainless, controlled heat input on brass, clean
deep relief — each as a layer preset carrying its own `M39P` value.

## Second differential — frequency, same method

Two more real MOPA jobs, identical except for the **frequency** setting:

```diff
- M38F30
+ M38F151
```

Again the **only** differing line across the entire capture. `M39P` did not move.

**Both MOPA parameters are now confirmed independently, each by its own controlled diff:**

```gcode
M38F<n>      ; MOPA frequency      CONFIRMED-vendor
M39P<n>      ; MOPA pulse width    CONFIRMED-vendor
```

Observed values so far: `F30`, `F48`, `F75`, `F151` · `P200`, `P500`.

## Units — not yet established

`P200` / `P500` and `F48` / `F75` are MakeIt's own numbers. Whether `P` is nanoseconds and `F` is
kilohertz is the natural reading and matches typical JPT MOPA ranges, **but the mapping between
MakeIt's UI units and the G-code value has not been verified.** Before publishing a material
library, confirm what MakeIt's pulse-width field is labelled in and whether the G-code value is
identical or scaled.

## What to do next

1. ~~Confirm `M38F` the same way~~ — **done, see above.**
2. **Establish the accepted ranges** for each, so a profile does not offer values the firmware
   rejects. Observed so far: F 30–151, P 200–500.
3. **Then add them to the profiles** as per-layer custom G-code. They are now `CONFIRMED-vendor`
   codes rather than guesses — but this project's rule is that a profile ships nothing that has
   not been demonstrated end to end, and *emitting* them from LightBurn is still untested.
   That is Stage 3.
