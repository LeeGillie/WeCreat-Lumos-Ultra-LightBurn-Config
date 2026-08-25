# Stage 4, Test 1 — `MPos` is a stub. Position readback is not available.

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04** · **COM7**
**Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED-hardware

## First attempt — not actually connected

An initial run produced a flood of bare `G0` lines, no `ok`, and no status reports. The retry
showed `Waiting for connection...` at the top, so **the device was not connected** during that
attempt — the machine was off or still booting. The `G0` stream was an artifact of the
disconnected state, not controller output. Recorded so nobody chases it later.

## Second attempt — properly connected

```
Waiting for connection...
ok
[WeCreat Lumos :ver 000240]
Found WeCreat Device
ok
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
?
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
ok
G90
ok
G0X10Y10
ok
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
?
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
ok
G0X0Y0
ok
?
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
```

Banner, device detection, and an `ok` for every command. The serial path is healthy.

## The finding

**Every field of the status report is frozen.** `MPos` reads `0.000,0.000,0.000` before
`G0X10Y10`, after it, and after `G0X0Y0`. `WCO` is always zero, `FS` always `0,0`, state always
`Idle`, `Pn` always `Z`.

Cross-check from [Stage 3](stage3-lightburn-connect-benchy.md): the identical string appears
there **during an active job stream**, immediately after `Starting stream` — still `Idle`, still
all zeros. A controller genuinely executing a job does not report `Idle`.

> ### The status report is a canned string, not live telemetry.
>
> This fits the pattern already established for this firmware: `$` returns a bare `ok` and `$$`
> returns nothing useful. WeCreat implemented just enough GRBL surface to satisfy a host program.
> Real motion state lives on the other side of the MCU boundary and is never exposed.

## Consequences

| Affected | Consequence |
|---|---|
| **Test 1 as written** | Unanswerable. There is no live `MPos` to compare against a commanded position. Not a failure — the question was invalid |
| **Position verification generally** | Cannot be done in software. **All calibration must be visual**, via the red pointer |
| **LightBurn position readout** | The Move window's coordinate display will show zeros regardless of machine state. Expected; not a bug to chase |
| **"Go to position", jog readback** | Unreliable for the same reason |
| **Job flow control** | Unaffected. LightBurn's GCode streaming is driven by counting `ok` responses, not by status polling, and `ok` is being returned correctly |
| **Job-complete detection** | Suspect. A permanently `Idle` device gives LightBurn nothing to wait on |

## What did *not* fail

`G90`, `G0X10Y10` and `G0X0Y0` were all accepted with `ok` and **no `err:20`**. Bare `G0` motion
in absolute mode is inside the firmware's vocabulary. Whether the galvo actually moved is exactly
what Test 2 exists to answer, and on this machine only the red pointer can answer it.

## Status

Test 1 **closed as inapplicable**. Proceed directly to Test 2 — the visual corner test is now the
only calibration route available, which raises its importance rather than lowering it.
