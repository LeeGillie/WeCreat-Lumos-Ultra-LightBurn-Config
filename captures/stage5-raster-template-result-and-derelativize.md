# `Raster Move` template does NOT control `G91` — so we convert the file instead

**Date:** 2026-08-26 · **Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED

## ❌ Result: the template is not the lever

`Device Settings → Custom GCode → Raster Move` was set to
`G1 X{x} Y{y} S{power} F{speed}` and the same Plain Fill job re-saved.

| | original | with Raster Move template |
|---|---|---|
| `G91` at line | 21 | **21** |
| Moves in relative mode | 9,634 | **9,634** |
| Moves in absolute mode | 3 | **3** |
| File size | 122,746 B | 135,523 B |

**Byte-for-byte the same structure.** The template changed only number *formatting*
(`F10000` became `F10000.02`), which is the entire reason the file grew.

> **The `Raster Move` template governs how each move line is formatted, not whether LightBurn
> works in relative or absolute mode.** The `G91` decision is made by the raster engine and is not
> exposed as configuration.

That closes the last configuration-level route to removing the amplifier.

## ✅ So remove it after the fact — `tools/derelativize-gcode.ps1`

If LightBurn will not emit absolute coordinates, the file can be rewritten to absolute before it is
sent. The arithmetic is exact and mechanical: track position, accumulate each delta, emit the sum.

```
.\tools\derelativize-gcode.ps1 -Path ".\captures\Plain Fill.gc"

  converted 9634 relative moves to absolute
  final tracked position: X77.720 Y108.699
  written: ...\Plain Fill - absolute.gc
```

Then in LightBurn use **Run GCode** to send the converted file.

### Validation

The converted output's coordinate range matches the job's own declared bounds **exactly**:

```
;Bounds: X48.784 Y82.637 to X123.216 Y125.199     <- LightBurn's own header

X range: 48.784 .. 123.216      ✅ exact
Y range: 82.637 .. 125.199      ✅ exact
```

Every one of 9,634 converted moves lands inside the original envelope, and the extremes touch the
declared limits precisely. If the conversion were drifting, that would not hold.

**The script prints this check itself.** If the range does not match the `;Bounds:` comment on line
3, do not run the file.

## What this does and does not achieve

**It does not fix the stalls.** The stream will still stall; the acknowledgement protocol is
unchanged.

**It makes stalls survivable.** In relative mode a lost line corrupts every subsequent position
permanently — measured at 2.3 mm outside the workpiece
([capture](stage5-drift-measured-and-pause-harm.md)). In absolute mode the very next line states
where the beam belongs, so a lost line costs **one missing segment** and nothing more.

That is the difference between a ruined workpiece and a small blemish. On a machine this
temperamental, it is worth more than fixing the stall would be.

**Cost:** the file roughly doubles in size (122 KB → 242 KB). Absolute coordinates are longer
strings than deltas, which is precisely why LightBurn uses `G91` in the first place. More bytes on
a link we already suspect is marginal is a real trade — worth measuring whether it makes stalls
*more* frequent even as it makes them less harmful.

## Status of the streaming investigation

| Lever | Result |
|---|---|
| Target buffer size | ❌ clamped by LightBurn, not settable |
| `Raster Move` template | ❌ does not control relative/absolute |
| Air On/Off templates | ⬜ untested — will at least remove the rejected `M8` |
| Baud rate | ⬜ untested — still live, since MakeIt does not use the serial path |
| CH340 re-enumeration (`COM6` → `COM9`) | ⬜ unchecked — would sit underneath everything else |
| **Post-process to absolute + Run GCode** | ✅ **available now** |
| Upload bridge over `192.168.42.1` | ⬜ the architecture that avoids streaming entirely |
