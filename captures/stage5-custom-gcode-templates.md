# The Custom GCode tab — template blocks, and where `M18S0` belongs

**Date:** 2026-08-25 · **LightBurn 2.1.04** · **Contributor:** Lee Gillie
**Evidence grade:** CONFIRMED-vendor (LightBurn's own UI)

## `StartGCode` is vestigial for this device class

A profile carrying `"StartGCode": "M18S0"` was imported and run. **The job did not cut and the fan
did not start** — the source was never selected. The Custom GCode tab has no "Start G-code" box at
all. The key exists in the prefs schema but the driver ignores it.

**Do not put job-start commands in `StartGCode` for a Custom GCode device.** Use the template
blocks below.

## The template blocks

*"Configure your gcode profile templates below."* Observed, in UI order:

| Block | Default shown | Empty? |
|---|---|---|
| **Job Header** | — | ✅ empty |
| Home | `$H` | placeholder |
| Focus Z | — | ✅ empty |
| **User Start Script** | — | ✅ empty |
| **User End Script** | — | ✅ empty |
| **Tool On** | `M4` | placeholder |
| 2nd Tool On | — | ✅ empty |
| Tool Off | `M5` | placeholder |
| Fire On | `M3` / `G1 F100 S{power}` | placeholder |
| Fire Off | `S0` / `G0` / `M5` | placeholder |
| Pierce | `M3` / `G1 F100 S{power}` / `G4 P{dwell}` / `G1 S0` / `G0` / `M4` | placeholder |
| *(air off)* | `M9` | placeholder |
| **Layer Start** | — | ✅ empty |
| Cut Move | `G1 [X]{x}[Y]{y}[Z]{z}[A]{rot}[S]{power}[F]{speed}` | placeholder |
| Raster Move | — | ✅ empty |

Templates support substitution: `{power}`, `{speed}`, `{x}`, `{y}`, `{z}`, `{rot}`, `{dwell}`.

**This explains the emitted job exactly.** The `M4` we see comes from **Tool On**; the `M5` from
**Tool Off**; `G1 ...S...F...` from **Cut Move**. None of it was arbitrary — it is all template
output.

## Options panel

| Option | Value |
|---|---|
| **GCode Flavor** | **WeCreat** — a built-in flavor, confirming `GCodeFlavor: "wecreat"` is a real LightBurn option |
| Dwell Units | seconds |
| Comment Characters | `;` |
| Escape Character | `^` |
| Verbose Output | on |
| Tool State Automatic | on |
| Variable Laser Power | on |
| **Enable Q-Pulse Options** | **off** ← see below |
| Supports G53 command | on |

## 🎯 `Enable Q-Pulse Options` exists on this device class

[docs/09](../docs/09-k9-and-mopa-limits.md) states that Q-Pulse Width is gated to LightBurn's galvo
device classes and unavailable to us. **There is a toggle for it right here on a Custom GCode
device.**

If enabling it exposes a per-layer Q-pulse width control, MOPA pulse width becomes a first-class
LightBurn parameter rather than something smuggled in as custom G-code — which would be a
substantially better answer than [docs/14](../docs/14-mopa-parameters-in-lightburn.md) proposes.

**Not tested yet. One variable at a time.** Flagged for immediately after source select is solved.

## Where `M18S0` should go

Three candidates, all plausible:

1. **Job Header** — earliest, once per job
2. **User Start Script** — the field explicitly intended for user additions
3. **Tool On** — fires immediately before the laser is enabled, and is idempotent if repeated

**Tool On is the most robust**, because it re-asserts the source every time the laser is armed,
which matters on a machine where `\x18` clears the selection.

### The single test that identifies all of them

With `Verbose Output` on, put a distinct inert comment in each empty block plus the real command in
Tool On, then run one job and read the echo:

```
Job Header          ;BLOCK-JOBHEADER
User Start Script   ;BLOCK-USERSTART
Layer Start         ;BLOCK-LAYERSTART
Tool On             M18S0
                    M4
```

One run then reveals **which blocks fire, in what order**, and whether the job cuts.

> ⚠️ **`Tool On` must keep `M4`.** The `M4` shown in that box is a greyed *placeholder*, not
> content. Typing into the field replaces the default entirely — enter both lines, or the laser
> never gets enabled and nothing marks.
