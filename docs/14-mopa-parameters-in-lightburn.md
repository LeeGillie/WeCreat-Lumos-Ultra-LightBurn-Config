# 14 — Driving MOPA Frequency and Pulse Width from LightBurn

**Status: the codes are confirmed; emitting them from LightBurn is not yet tested.**
Read [SAFETY.md](../SAFETY.md) first. Do not use this on real work until Stage 3 has verified
that LightBurn's output reaches the machine intact.

## The two codes

Both established by controlled differential capture of MakeIt's own G-code — one job, one
parameter changed, everything else fixed. Each produced exactly one differing line.
([evidence](../captures/stage5-mopa-pulsewidth-CONFIRMED.md))

```gcode
M38F<n>      ; MOPA frequency
M39P<n>      ; MOPA pulse width
M18S0        ; select the MOPA fiber source   (M18S1 selects UV)
```

Values observed in the wild: `F30`, `F48`, `F75`, `F151` · `P200`, `P500`.

**Units are not established.** Nanoseconds and kilohertz are the natural reading and fit typical
JPT MOPA ranges, but nobody has verified the relationship between MakeIt's UI field and the
emitted number. Establish that before building a material library on it.

## Why this needs custom G-code at all

LightBurn *does* have Frequency and Q-Pulse Width fields — in its **galvo** device class. The
Lumos Ultra presents to LightBurn as a **GRBL** device
([why](01-architecture.md#1-the-headline)), whose cut settings are speed, power, passes, interval
and the ordinary G-code set. No frequency field, no pulse-width field.

The workaround is that LightBurn's GRBL class supports **per-layer custom G-code**, which is the
same granularity a material library needs anyway.

## How to set it per layer

In LightBurn, for each cut layer:

**Cut Settings Editor → Advanced → Layer G-Code**

Put the parameters in that layer's start G-code:

```gcode
M18S0
M38F75
M39P200
```

Every layer can carry different values. So a single job can run one pass at a short pulse for
marking and another at a long pulse for depth, which is exactly the kind of thing a MOPA is for.

## Suggested library structure

Rather than remembering numbers, build named layer presets:

| Preset | `M38F` | `M39P` | Intended for |
|---|---|---|---|
| Brass — shallow mark | | | fill in from your own testing |
| Brass — deep relief | | | |
| Stainless — colour | | | colour marking is very pulse-width sensitive |
| Anodised — clean white | | | |

**Deliberately left blank.** Publishing numbers we have not tested would be exactly the kind of
confident guess this project refuses to make. Fill them in from your own material tests and
contribute them back with the material, the source, and the resulting appearance.

## Before trusting this

1. **Verify the units** — change MakeIt's field by a known amount and confirm the emitted value
   moves the same way.
2. **Find the accepted ranges.** The firmware may clamp, reject, or silently ignore out-of-range
   values. An ignored value is the dangerous case: the job runs at whatever was set last.
3. **Confirm LightBurn's output actually arrives.** Run a job from LightBurn with these codes,
   then read the resulting G-code back off the controller with
   `tools/stage5-jobfile-grab.ps1` and check they survived. This is the whole point of
   [Stage 3](03-bringup-plan.md).
4. **Verify on scrap, at low power**, with the red lens fitted and 800–1100 nm goggles.

## What this does not give you

Frequency and pulse width, and that is a great deal. It does **not** give you LightBurn's
galvo-class features — 16-bit depth-map relief, 3D sliced images, lens correction, split marking.
Those need the galvo device class itself, not just its parameters. See
[09-k9-and-mopa-limits.md](09-k9-and-mopa-limits.md).
