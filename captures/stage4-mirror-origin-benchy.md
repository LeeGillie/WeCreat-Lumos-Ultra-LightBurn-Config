# Stage 4, Test 2 — origin corner resolved, and `MPos` is live after all

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04** · **COM7**
**Lens:** red / MOPA · **Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED-hardware

## The test

A 20 mm square at **X 10, Y 180** — deliberately pushed into one corner, because a centred square
cannot detect mirroring. Framed with the red pointer. No beam.

| Origin setting | Screen shows | Pointer traces | Agree? |
|---|---|---|---|
| bottom-left (LightBurn wizard default) | upper-left | **lower-left** | ❌ |
| **top-left** | lower-left | **lower-left** | ✅ |

**Resolved: the origin corner is top-left (rear-left).** WYSIWYG now holds — the screen and the
machine agree.

## Where this setting lives

There is **no `MirrorX` / `MirrorY` checkbox** on the Custom GCode device class. LightBurn exposes
the same thing as the **Origin** 2×2 corner selector on the *Dimensions / Units* tab of Device
Settings. Anyone following this repo will look for the mirror checkboxes and not find them.

## What actually changed — read this before assuming

**The emitted G-code did not change.** Byte-identical before and after:

```gcode
G00 G17 G40 G21;Restore metric mode
G54
G90;Restore absolute mode
G0 X10Y180
G1 Y200F800
G1 X30
G1 Y180
G1 X10
G90;Restore absolute mode
M2
```

`MPos` also unchanged at `-95.000, 75.000`. So the Origin setting flipped LightBurn's **display**,
not its output. The machine was always going to put that square in the lower-left; what we fixed
is LightBurn's picture of where that is.

That is the correct fix — the machine is ground truth and the screen now matches it — but it is
worth being precise, because "we fixed the mirroring" would imply the G-code changed. It did not.

## `MPos` is live. Retracting the earlier "stub" call.

[The previous capture](stage4-console-g0-flood-benchy.md) concluded the status report was canned,
because `MPos` stayed at zero through a console `G0X10Y10`. That was wrong, and this run disproves
it:

```
G0 X10Y180  →  ... G1 X10        job ends at X 10, Y 180
<Idle|MPos:-95.000,75.000,0.000|...>
```

- X: 10 − 105 = **−95** ✅
- Y: 180 − 105 = **75** ✅

**A constant −105 offset on both axes — exactly `M107X-105Y-105`.** The field-centre origin we
confirmed from MakeIt's own G-code, now independently visible from the LightBurn side. Two
unrelated methods, same answer.

The earlier zero reading has a different explanation: **a console `G0` is parsed and acked but does
not move the galvo.** Motion happens only inside a streamed job, once the controller is in preview
or marking mode. So `ok` on a typed `G0` means "understood", not "executed".

## LightBurn has native WeCreat support

Around every framing run LightBurn emits:

```
Exit_Preview_Mode
M41Y1
```

Neither is generic GRBL and neither comes from us. **`GCodeFlavor: "wecreat"` is doing real work
inside LightBurn 2.1.04** — it knows this controller's preview mode. `M41` is the preview/pointer
control, matching MakeIt's own `M41S0` in its framing preamble
([Stage 5](stage5-framing-mopa-benchy.md)).

This is why the red pointer lit up at all, and it retires the open worry that LightBurn would have
no way to drive it.

## `err:20` — consistent with the M8/M9 reading, not yet proven

Framing runs produce **zero** `err:20`. Framing omits `M4`, `M5`, `M8`, `M9`; `M5` is separately
confirmed `ok` in this same log, and MakeIt itself uses `M4S1000`. That leaves `M8`/`M9` — two
commands, two errors. Still needs the confirming run with air assist disabled.

## Open

- Independent corner re-check (move the square to a different corner and confirm it follows)
- Test 3 — scale, 100 mm with calipers
- Test 4 — 200 mm at the field edge, looking for bow
- Capture `prefs.ini` to read the exact stored key values for the top-left origin, rather than
  guessing what the generator should emit
