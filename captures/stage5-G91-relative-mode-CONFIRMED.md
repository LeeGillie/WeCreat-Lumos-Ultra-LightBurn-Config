# ✅ `G91` CONFIRMED in fills — and it explains both failure shapes

**Date:** 2026-08-26 · **Source:** LightBurn's own saved G-code, `Offset Fill.gc` / `Plain Fill.gc`
**Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED — LightBurn output, no inference

The G91 hypothesis was **correct**. Every vector capture up to now was pure `G90` absolute; fills
are not.

## The measurement

| | Offset Fill | Plain Fill |
|---|---|---|
| Total motion lines | 11,674 | 9,637 |
| **Moves in `G91` relative mode** | **1,009 (8.6 %)** | **9,634 (99.97 %)** |
| Moves in `G90` absolute mode | 10,665 | **3** |
| **Absolute `G0` re-anchors** | **459** | **2** |

`Plain Fill.gc` enters `G91` at **line 21** and does not leave it until **line 8,647** — over
**8,600 consecutive relative moves with no absolute re-anchor anywhere inside**.

```gcode
G0 X66.807Y123.637
;Layer C01
G91                        <- relative mode
G1 X-4.167S0F10000
G1 X-0.011S55
G1 X-4.167S0
G1 X-9.678Y-0.1
...                        ~8,600 more, every one relative to the last
```

## Why this predicts exactly what was observed

**Relative moves accumulate error. Absolute moves erase it.**

If a single line is lost or unacknowledged:

| Mode | Consequence |
|---|---|
| `G90` absolute | Damage stops at the **next absolute coordinate**. One small defect, then correct again |
| `G91` relative | **Every subsequent position inherits the error, permanently** |

Now map that onto the reported symptoms:

> *"With Offset Fill, portions of some letters would be only partially engraved — and it was always
> the same letters."*

Offset Fill re-anchors **459 times**. A lost line corrupts only until the next `G0`, so the damage
is **local** — a partial letter, then recovery. And because the same geometry provokes the same
failure point in the stream, it is **the same letters every run**.

> *"Using Fill it froze and I restarted it, but all of the artwork for the remainder of the
> engraving was shifted to the right."*

Plain Fill re-anchors **twice in the entire job**. A lost line inside that 8,600-move relative
block shifts **everything after it, for the rest of the job**. There is no absolute coordinate left
to recover on.

**Two different symptom shapes, from one root cause, predicted quantitatively by the G90/G91 ratio.
That is about as clean as diagnostic evidence gets.**

## What this does and does not tell us

**It does not identify the root cause.** `G91` is an *amplifier*, not the fault. Something is still
dropping a line or an acknowledgement — the stalls prove that independently.

**It does tell us the two faults are the same fault.** Stalls (a lost `ok`) and shifted artwork (a
lost command) are both symptoms of a desynchronised stream. We have been treating them as separate
problems; they are not.

## Immediate mitigation: prefer Offset Fill

Not a fix — a **10× reduction in blast radius**. 8.6 % relative exposure with 459 recovery points,
versus 99.97 % with 2. Until the stream is reliable, Offset Fill degrades gracefully and Plain Fill
does not.

Worth putting in the README: **on this machine, Plain Fill has no error recovery.**

## Still emitting `M8`

Both files contain `M8` (air assist on) — the code this firmware rejects with `err:20`
([analysis](stage4-airassist-differential.md)).

**Blank the `Air On` and `Air Off` templates** in Device Settings → Custom GCode. That removes both
codes from the stream entirely rather than swapping `M8` for `M9`.

Not the cause of the stalls, but it is a known-rejected command sitting in every job, and it costs
nothing to remove.

## The start and end scripts are working

```gcode
;USER START SCRIPT
M41Y1
M18S0
;USER START SCRIPT
...
;USER END SCRIPT
M15S0
;USER END SCRIPT
```

Exit preview, select source, and stop the fan at job end — all carried by the profile, all present
in the emitted job. That part is solved.

## Next lever, still untested

**`TargetBufferSize`, currently 128.** If this controller's receive buffer is smaller than standard
GRBL's, LightBurn overruns it — and an overrun drops commands *and* desynchronises
acknowledgements, which is precisely the pair of symptoms we have.

Try **40**, then **15**. It remains the most promising untested change, and nothing found so far
argues against it.
