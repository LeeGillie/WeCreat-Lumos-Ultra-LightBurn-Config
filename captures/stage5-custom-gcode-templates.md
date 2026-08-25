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

---

## The documented list — 29 blocks, not 15

LightBurn documents these properly:
<https://docs.lightburnsoftware.com/2.1/Reference/DeviceSettings/CustomGCode/>

| Template | Trigger (documented) |
|---|---|
| Home | once per job |
| Focus Z | once per job |
| **User Start Script** | **"Custom script to run at the start of the job"** |
| **User End Script** | "Custom script to run at the end of the job" |
| **Tool On** | "Enable the tool" — per tool activation |
| 2nd Tool On | per 2nd tool activation |
| Tool Off | per tool deactivation |
| Fire On / Fire Off | per laser firing / stop |
| Pierce | initial firing without movement |
| Dwell | per pause command |
| **Air On / Air Off** | **per air assist activation / deactivation** |
| **Layer Start** | "Commands to run before the start of each layer" |
| Cut Move | per cutting motion |
| Raster Move | per raster motion |
| **Rapid Move** | **per non-cutting motion** |
| Safe Rapid | per safe-height rapid |
| Abort / Pause / Resume | per corresponding command |
| Job End | job completion |
| Get Position / Get Status | per query |
| Metric Modal / Imperial Modal | per unit setting |
| Work Coordinate System | per WCS selection |
| Custom Error Codes / Custom Alarm Codes | per error / alarm |

Substitution variables: `x`, `y`, `z`, `r`/`a`/`u`/`rot`/`rotation`, `x_probe`, `y_probe`,
`z_probe`, `s`/`speed`, `feed`/`feedrate`, `p`/`power`, `rpms`/`spindlespeed`, `dwell`, `tool`.

**Note:** the UI in 2.1.04 also shows a **Job Header** block that the documentation does not list.
Undocumented, and its trigger is unverified.

## This solves three of our open problems, not one

Every symptom we have been fighting is a template we can edit.

### 1. Source select → `User Start Script`

Documented as running at the start of the job. `M18S0` (MOPA) or `M18S1` (UV).
`Tool On` remains the more robust option because it re-asserts on every arm, and `\x18` clears the
selection — worth testing both.

### 2. `err:20` → blank the `Air On` / `Air Off` templates

There are dedicated **Air On** and **Air Off** blocks. `M8` and `M9` are template output, not
hardcoded. **Emptying them removes the air-assist codes from the stream entirely**, regardless of
what the layer's Air toggle says.

That is a real fix rather than "turn air assist off and hope", and it explains the earlier
confusion: air-off swapped `M8` for `M9` because both come from templates, and *neither* state
produces *no* command.

### 3. The rapid-travel scar → `Rapid Move`

The dotted line from field centre to the job's start corner is the beam staying lit through a `G0`
([capture](stage5-first-mark-and-travel-scar.md)). There is a **Rapid Move** template governing
exactly those moves.

If it can carry an explicit `S0` — the way MakeIt's own framing geometry states
`G1X90.1Y96.21S0` — the beam is forced off during travel **in the profile**, with no dependency on
whether the firmware implements `$32` laser mode.

That would be a considerably better fix than a GRBL setting we cannot even read back.

## Revised plan

One variable at a time, in this order:

1. `User Start Script` = `M18S0` → confirm the job cuts unaided
2. Blank `Air On` and `Air Off` → confirm `M8`/`M9` vanish from the echo
3. Inspect the `Rapid Move` default, then add `S0` → confirm the travel scar vanishes
4. Only then try `Enable Q-Pulse Options`

Each is observable in the console echo with `Verbose Output` on, and steps 1–3 need at most one
small mark each.

---

## ✅ `User Start Script` works — CONFIRMED-hardware

`User Start Script` = `M18S0`. The stream echo now shows:

```
Starting stream
M18 S0            <- the controller's own echo, normalised with a space
Stream completed in 0:00
```

That is the controller acknowledging the command, exactly as it does for a console-typed `M18S0`.
**Source select now travels with the profile.** No console command, no user folklore.

`StartGCode` is dead; `User Start Script` is the answer.

## 🔴 Two follow-on defects

### 1. Every operation needs a preceding **Stop**

Observed: neither Frame nor Start does anything until **Stop** is pressed first. Stop, then frame
works. Stop again, then Start cuts.

Stop sends three things:

```
\x18                 (0x18 = soft reset)
Exit_Preview_Mode
M41Y1
```

So the machine is being left in **preview mode** after each operation, and nothing but Stop clears
it. `M41Y1` is evidently the exit — matching MakeIt's own `M41S0` in its framing preamble, where
`M41` is the preview/pointer control.

**Candidate fix — prepend the exit to the start script:**

```
M41Y1
M18S0
```

Order matters: leave preview first, then select the source.

If `M41Y1` alone is insufficient, the `\x18` soft reset may be the operative part. LightBurn's
**Escape Character** is `^`, so `^X` in a template *may* emit 0x18 — untested, and it would have to
come **before** `M18S0`, since a reset clears the source selection.

### 2. The fan is left running after the job

`M18` starts the exhaust fan as part of arming the source. Nothing turns it off.

**Candidate fix — `User End Script` = `M15S0`.** `M15` is the exhaust control in our dictionary
([docs/04](../docs/04-mcode-dictionary.md)); MakeIt sends `M15S0` in its beam-free framing preamble
and `M15S1`/`M15S70` when marking. **CONFIRMED-vendor**, so this is not a blind M-code.

Judgement call worth making deliberately: extraction usually *should* run on after a job. `M15S0`
at job end stops it immediately. Acceptable for fiber marking on anodized aluminium; less so for
UV work on organics. May belong in the UV profiles with a delay, or not at all.

## Test order from here

1. `User Start Script` = `M41Y1` + `M18S0` → does Frame/Start work without a preceding Stop?
2. `User End Script` = `M15S0` → does the fan stop?
3. Blank `Air On` / `Air Off` → do `M8`/`M9` leave the stream?
4. `Rapid Move` + `S0` → does the travel scar go?
5. `Enable Q-Pulse Options`
