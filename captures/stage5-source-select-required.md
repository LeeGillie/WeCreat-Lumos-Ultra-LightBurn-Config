# `M18S0` is REQUIRED — and once sent, **Frame fires the beam**

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **Lens:** red / MOPA
**Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED-hardware

## 🚨 SAFETY FINDING — read before framing again

> **After the source has been selected, LightBurn's Frame button can MARK, not just point.**
>
> Observed directly: a framing pass **cut a visible line** in the workpiece.

### Why

LightBurn's framing G-code for this device class carries **no power term and no laser-mode command
at all**:

```gcode
G00 G17 G40 G21;Restore metric mode
G54
G90;Restore absolute mode
G0 X10Y180
G1 Y200F800     <-  G1. No S value. No M4/M5 anywhere in the job.
G1 X30
G1 Y180
G1 X10
M2
```

`G1` is a *cutting* move. With no `S` in the job, the controller uses the **modal `S` left over
from whatever ran previously** — a marking job at 40 % leaves `S400` sitting there. And with the
source now selected by `M18S0`, that is a live beam tracing your frame.

Compare MakeIt, which never has this problem: its framing geometry carries an explicit
`G1X90.1Y96.21**S0**` — **power zero, stated outright.** LightBurn omits it and inherits.

### Mitigation until this is properly solved

**Send `M5` and `S0` in the Console before every Frame**, once a marking job has run:

```
M5
S0
```

Treat **Frame as a beam operation** on this machine: goggles on, lid closed, workpiece secured.
The Stage 4 framing work was safe only because the source had never been selected in that session.

**This must ship in the README as a prominent warning.** An Ultra owner who assumes "framing is
safe" — as every gantry-laser habit teaches — will be wrong.

## The finding that caused it: `M18S0` is required

**Symptom:** 15 %, 25 %, 40 % power at 12000 mm/min — **no mark at all.**
**Cause:** LightBurn never selects a laser source. The controller was not on the MOPA fiber.
**Fix:** `M18S0` → the machine marks.

LightBurn emits none of MakeIt's source setup:

| Code | Meaning | Emitted by LightBurn? |
|---|---|---|
| `M18S0` | **Source select — MOPA fiber** (`S1` = UV) | ❌ |
| `M38F48` | frequency | ❌ |
| `M39P200` | pulse width | ❌ |
| `M4S1000` | dynamic power mode | ✅ (as bare `M4`) |

**Without `M18S0` the machine is silent at any power setting.** That is a trap with a nasty shape:
an owner climbs the power scale getting nothing, and the moment the source *is* selected they are
at full power on a workpiece.

## Consequences for the profiles

`M18S0` (MOPA) / `M18S1` (UV) belongs in **device Start G-code**, not in a per-layer block — it is
a property of the profile, and each published profile is already lens- and source-specific.

Open question this raises: **the start G-code must also leave the beam safe.** Selecting the source
at job start is what makes a later Frame dangerous. Candidate: pair the source select with an
explicit `M5` and `S0`, and investigate whether End G-code can deselect the source.

## Status

- `M18S0` required for MOPA marking — **CONFIRMED-hardware**
- Frame fires once a source is selected — **CONFIRMED-hardware**, safety-critical
- Whether `M38F`/`M39P` are also required, or merely default to usable values — **open**
- Power floor on this material — **open**, the 15–40 % sweep was invalid (no source selected)
