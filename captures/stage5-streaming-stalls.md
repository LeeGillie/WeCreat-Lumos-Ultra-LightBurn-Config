# Streaming stalls — LightBurn is pacing a machine that never reports being busy

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie
**Status:** 🔴 OPEN — the most serious defect found so far

## Symptoms

1. Neither Frame nor Start does anything until **Stop** is pressed — sometimes twice
2. A running job **stalls mid-stream and hangs**. Pressing **Pause**, waiting, then **Pause**
   again restarts it
3. On a long job (a Material Test grid) it stalls **repeatedly**
4. The fan is left running at job end until Stop is pressed

Operator's read: *"It seems like LightBurn is not using any kind of flow control."*

## The likely root cause — and we already had it in hand

**The status report never changes.** Every `?` on this machine returns:

```
<Idle|MPos:...|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
```

The **state field is permanently `Idle`** and **`FS` is permanently `0,0`** — including during an
active job stream ([Stage 3](stage3-lightburn-connect-benchy.md), where the identical string
appears immediately after `Starting stream`).

A real GRBL controller reports `Run` while executing, `Hold` when paused, and live feed/speed in
`FS`. **This one reports none of it.** Position updates; nothing else does.

That has a direct consequence:

> **LightBurn cannot tell whether the machine is busy.** It sees a device that is always idle,
> always ready, with an empty planner.

The corroborating symptom is already in the logs: **`Stream completed in 0:00`** for jobs that
visibly take much longer to run. LightBurn finishes pushing bytes, sees `Idle`, and declares the
job done while the machine is still marking.

So the stalls are not LightBurn failing to *do* flow control — they are LightBurn doing it against
telemetry that lies.

## Why MakeIt does not have this problem

**MakeIt does not stream.** It uploads the whole job to the controller's SD card and the controller
executes it locally — confirmed by the **302 MB `gcode.gc`** found at
`/mnt/SDCARD/data/printing/` ([Stage 5](stage5-framing-mopa-benchy.md)).

A vendor app that never streams never needs the acknowledgement protocol to be correct. That is
very likely *why* it is not correct.

**The Genmitsu comparison is fair**, though: that is a real GRBL device, streamed over USB, and it
behaves. The differences are that it runs at **115200 baud** rather than **1,000,000**, and it
implements the status protocol properly.

## What to test, cheapest first

### 1. `?` during a stall ⭐ the decisive one

When the job hangs, type `?` in the Console and read the **state field**.

| Reply | Meaning |
|---|---|
| `<Idle\|...>` while the machine is mid-job | Confirms the status report is a stub and LightBurn is flying blind |
| `<Hold\|...>` | A genuine feed hold — machine-side, not a flow-control bug. Different problem, different fix |
| `<Run\|...>` | The status *does* work sometimes, and the model above is wrong |

Costs nothing and discriminates between three very different explanations.

### 2. Reduce `TargetBufferSize`

Currently **128**, matching standard GRBL's RX buffer. If the WeCreat controller's real buffer is
smaller, LightBurn overruns it and the machine wedges.

Try **40**, then **15**. Device Settings → the buffer size field. Lower is slower but safer.

### 3. Eliminate the USB hub

Worth removing as a variable, though note the machine has an **internal hub** that cannot be
bypassed — the single cable already fans out to the CH340 and the RNDIS gadget
([docs/01](../docs/01-architecture.md)).

### 4. Lower the baud rate

1,000,000 baud through a CH340 behind a hub is aggressive. The Genmitsu manages at 115200. Whether
this controller accepts a lower rate is unknown.

## Implication for the project

If this cannot be fixed in configuration, it changes what v1.0 can honestly claim. A profile that
marks correctly but stalls on any job larger than a test square is not "works" — it is "works for
small vectors".

It also promotes the **`weburn`-style upload bridge** from a deferred nicety
([ROADMAP](../ROADMAP.md)) to the architecturally correct answer. Uploading a job and letting the
controller run it is exactly what MakeIt does, and exactly what sidesteps a broken ack protocol.

**Do not paper over this in the README.** An owner who hits mid-job stalls on a real workpiece
needs to have been warned.
