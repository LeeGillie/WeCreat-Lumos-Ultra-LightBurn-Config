# Stage 3 — profile accepted, camera working, `err:20` on stream

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04** · **COM7**
**Contributor:** Lee Gillie

## Console

```
ok
[WeCreat Lumos :ver 000240]
Found WeCreat Device                    <- the warning is GONE
ok
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
Starting stream
<Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
err:20
err:20
```

## Two wins

### The device class is correct

**`Found WeCreat Device`** replaced *"you are not using a custom gcode device with the WeCreat
device flavor"*. The regenerated `Custom GCode` / `GCodeFlavor: wecreat` profile is what LightBurn
wants. `CONFIRMED-hardware.`

### The camera works

The Ultra's camera is usable from LightBurn. Combined with
[Stage 2](stage2-rest-benchy.md) — one accessible stream, arriving rotated ~90° and
lens-uncorrected — this closes **F1** in the feature inventory.

## The problem: `err:20`, twice

In GRBL's error table, **error 20 is "Unsupported or invalid G-code command found in block"**.
The controller received two lines it does not implement and rejected them.

Rejection is the safe failure: the command did not execute. Nothing fired, nothing moved.

### Why this is expected, and narrow

WeCreat's firmware implements a **subset** of G-code. We already know the settings subsystem is
stubbed — `$$`, `$#` and `$G` all return a bare `ok` and nothing else
([Stage 1](stage1-serial-benchy.md)). It is entirely consistent that a couple of the codes
LightBurn emits at job start are also absent.

We know exactly what the firmware *does* accept, because we captured MakeIt's own output
([Stage 5](stage5-uv-vs-mopa-benchy.md)):

```gcode
;wecreat 3.0.6
;canvas border: 0 0 210 210
M15S1  M107X-105Y-105  M57A450B30  M19S0  M18S0
G90  G4P1  M46A1B0  G0X105Y105
M25S1  M26S1  M24S15  M15S70  M59A-1000B50
M1S0  M4S1000  M11S0.08
G0Z47.8  M38F48  M39P200
G0F15000  G1F12000
```

Note what is **absent** from the vendor's preamble: no `G20`/`G21` units command, no `$H` homing,
no `M8`/`M9` air assist, no `G54`. Those are the obvious suspects for two unsupported lines.

## Diagnosis needed — capture what LightBurn sent

The console reports the errors but not the offending lines. LightBurn can write its output to a
file instead of streaming it:

**Laser window → `Save GCode`**

Save it to the share, then diff the preamble against MakeIt's above. The two extra commands will
be obvious, and the fix is either a device setting that suppresses them or a compensating entry.

## Candidate causes, in order

| Suspect | Why | Fix if confirmed |
|---|---|---|
| `G21` / `G20` units | MakeIt never sends one. `Units: 1` and `ControlUnits: 1` in the Custom GCode settings are untested values we inherited from LightBurn's wizard default | Try `Units: 0` |
| `$H` homing | `HomeOnStartup` is `false` in our profile, but a job may still request it | Confirm homing stays off |
| `M8` / `M9` air assist | LightBurn emits these when air assist is enabled on a layer | Disable air assist on the layer |
| `G54` work offset | Common in LightBurn output; MakeIt never uses it | Device setting, if exposed |

**Do not guess and paste.** Save the G-code, diff it, and fix the specific line — the same method
that has produced every confirmed result in this project.
