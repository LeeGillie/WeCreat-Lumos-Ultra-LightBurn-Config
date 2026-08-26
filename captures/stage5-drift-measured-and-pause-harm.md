# Drift measured — and Pause/Resume is part of the damage

**Date:** 2026-08-26 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie
**Evidence grade:** CONFIRMED — from LightBurn's own console log

## 🎯 The drift is now measurable

The job (`Plain Fill.gc`) declares its own extents in line 3:

```
;Bounds: X48.784 Y82.637 to X123.216 Y125.199
```

The final position reported at the end of the run:

```
<Idle|MPos:-47.968,-24.663,0.000|...>
```

Converting through the confirmed `−105` field-centre offset:

| Axis | MPos | = workspace | job's own bound | verdict |
|---|---|---|---|---|
| X | −47.968 | **57.032** | 48.784 – 123.216 | inside |
| Y | −24.663 | **80.337** | 82.637 – 125.199 | **2.30 mm BELOW the minimum** |

**The machine finished 2.3 mm outside the artwork's own declared bounding box.**

In a pure `G90` absolute job that is arithmetically impossible — every coordinate is stated
outright. It is only possible when position is *accumulated*, which is exactly what
`G91` does ([evidence](stage5-G91-relative-mode-CONFIRMED.md)).

This is the same mechanism behind *"after one restart it was going to run off the card so I had to
abort it"* — measured here at 2.3 mm, and unbounded in principle.

## ⚠️ Pause → Resume is not a safe recovery. It is part of the fault.

The log shows the technique used repeatedly to unstick the stream:

```gcode
G1 X4.167
!
!
~
G1 X3.1S50
~
G1 X2.9S0
```

`!` is GRBL feed hold; `~` is resume. Note the counts are **unbalanced** — `! !` then `~`, and
later `~ ~`.

A feed hold stops the machine **mid-move**. On resume, if the interrupted move does not complete to
exactly its intended endpoint — or if a buffered line is discarded — then:

- in **`G90` absolute** mode, the next coordinate corrects it. Harmless.
- in **`G91` relative** mode, **the error is permanent and inherited by every subsequent move.**

> **Pause/Resume unsticks the stream at the cost of shifting everything after it.**
>
> That is why the job kept running *and* wandered off the card. The recovery and the corruption are
> the same action.

**Recommendation: do not use Pause/Resume to rescue a fill job.** Abort and restart. A restart
costs material; a resume costs material *and* produces a plausible-looking result that is wrong.

## Per-layer re-anchoring — the one piece of good news

The log confirms LightBurn does restore absolute mode at layer boundaries:

```gcode
G90;Restore absolute mode
...
M8
G0 X74.42Y125.199        <- absolute re-anchor
G91                      <- back to relative for this layer's raster
```

So accumulated error is **reset once per layer**. It does not carry across the whole file — it
carries across one layer's raster, which for a dense fill is still thousands of moves.

More layers = more re-anchors = less exposure. Not a fix, but it explains why some jobs survive.

## `COM6` → `COM9`

The device would not work until the port was changed. A CH340 that has moved port number has
**re-enumerated** — Windows saw a new device instance.

Worth checking: Device Manager → View → *Show hidden devices*, and look for multiple ghost CH340
entries. If the bridge is re-enumerating spontaneously, that is a hardware-level cause that would
sit underneath everything else in this investigation, and it would explain dropped bytes far better
than any LightBurn setting.

## 🔬 The next test, and it is offline

**Define the `Raster Move` template explicitly.**

LightBurn emits `G91` for scan lines as a bandwidth optimisation when using its *default* raster
handling. The Custom GCode tab exposes a **Raster Move** template, currently empty, and the
documented substitution variables include absolute `{x}` and `{y}`.

If defining it forces absolute coordinates per move, **the `G91` amplifier disappears entirely** —
and a dropped line becomes one small defect instead of a ruined job.

Test costs nothing and needs no machine:

1. Device Settings → Custom GCode → **Raster Move** → `G1 X{x} Y{y} S{power} F{speed}`
2. **Save GCode** on the same fill job
3. Search the output for `G91`

- **`G91` gone** → the single most valuable fix available to this project
- **`G91` still there** → the template does not control it; fall back to Offset Fill and the
  upload bridge

## Standing recommendations

| | |
|---|---|
| Fill type | **Offset Fill** — 8.6 % relative exposure vs 99.97 % |
| Stall recovery | **Abort and restart. Never Pause/Resume on a fill.** |
| Air templates | Blank `Air On` / `Air Off` — `M8` is still in every job and is rejected |
| Layer count | More layers = more absolute re-anchors |
