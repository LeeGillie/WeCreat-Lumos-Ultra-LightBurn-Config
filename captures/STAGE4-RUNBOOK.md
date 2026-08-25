# Stage 4 runbook — field calibration (no beam)

Open this on benchy at
`\\cortex\D\DevHome\WeCreat Lumos Ultra Lightburn Config\captures\STAGE4-RUNBOOK.md`

**Goal:** resolve `MirrorX`, `MirrorY`, origin corner and scale, and find out whether the two
`err:20` lines actually matter. **No beam is fired at any point.**

---

## Pre-flight

| # | Check |
|---|---|
| 1 | **MakeIt is CLOSED.** It holds the COM port. If it has been open since the last power-up, power-cycle the Lumos |
| 2 | **Power on the Lumos**, let it finish booting |
| 3 | **Red lens fitted** (`H SL-1064-200-F290-D10-C`) — it already is |
| 4 | **Lid closed** |
| 5 | 800–1100 nm goggles within reach. Framing should fire nothing, but this is the first time we drive the machine from LightBurn and "should" is not "does" |
| 6 | Open LightBurn, connect to **COM7** |

You should see `[WeCreat Lumos :ver 000240]` and **Found WeCreat Device** in the console.

---

## Test 0 — does the red pointer even come on? ⚠️ read this first

**This is the one genuine unknown, and it decides whether the rest of the runbook works.**

Nothing moves in the work area on this machine. The *only* thing that makes framing visible is
the red aiming pointer. MakeIt turns it on with private M-codes in its own framing preamble
(`M41S0`, `M19S1`, `M42S0`, `M11S0.2` — we have the capture, we just don't know which one is the
pointer). **LightBurn sends none of them.**

So there is a real chance you will hit Frame and see absolutely nothing.

- **Pointer visible → carry on to Test 1.**
- **Nothing visible → stop and tell me.** Do *not* start pasting M-codes into Start G-code to
  hunt for it. `M3S100` looks tempting because it is in MakeIt's framing preamble, but under
  GRBL constant-power mode that can fire the source on `G0` moves. We will work it out from the
  captures instead.

Either way, do **Test 1** first — it works whether or not the pointer does.

---

## Test 1 — coordinates reach the controller (console only, ~3 min)

Beam-free, pointer-free, tells us the software path is sound before we trust anything visual.

LightBurn → **Laser window → Console tab.** Type each line, press Enter, write down the reply.

| # | Send | Expect | Record |
|---|---|---|---|
| 1 | `?` | `<Idle\|MPos:0.000,0.000,0.000\|...>` | |
| 2 | `G90` | `ok` | |
| 3 | `G0X10Y10` | `ok` | |
| 4 | `?` | MPos should now read **10, 10** | |
| 5 | `G0X0Y0` | `ok` | |
| 6 | `?` | back to **0, 0** | |

**What this tells us:** if MPos tracks the commanded values, LightBurn's coordinates are arriving
intact and the controller is accepting motion. If MPos never changes, nothing downstream of this
is meaningful and we stop here.

---

## Test 2 — mirroring and origin ⭐ the important one

> **A centred square cannot detect mirroring.** Mirror it and it lands in exactly the same place.
> This is why the test uses a **small square pushed into one corner** — where it ends up
> physically is the whole answer.

**Set up in LightBurn:**

1. New file. Confirm the workspace reads **210 × 210 mm**.
2. Draw a square, then use the numeric toolbar at the top to set it exactly:
   - **Width 20, Height 20**
   - **X 10, Y 180** (with the position origin set to the square's lower-left)
3. That puts a 20 mm square in the **upper-left** of the LightBurn workspace, well away from
   centre in both axes.
4. Select it. Press **Frame**.

**Watch where the pointer traces, and record which physical corner of the bed it lands in.**

| Pointer lands | Meaning |
|---|---|
| **Upper-left** (matches the screen) | `MirrorX: false`, `MirrorY: false` — wizard defaults correct |
| **Upper-right** | X is flipped → set **`MirrorX: true`** |
| **Lower-left** | Y is flipped → set **`MirrorY: true`** |
| **Lower-right** | both flipped → set **both true** |

Record it here:

```
Pointer landed in the ................................ corner
Screen said ......................................... upper-left
=> MirrorX = ..........   MirrorY = ..........
```

Sanity note: "upper" means the far side of the bed as you look into the machine, "lower" the near
side. If that is ambiguous on your bench, say which way you were facing when you wrote it down.

---

## Test 3 — scale (~5 min)

1. Set the square to **Width 100, Height 100**, **X 55, Y 55** (centred in a 210 mm field).
2. **Frame.**
3. Measure the traced square with calipers or a steel rule — corner to corner along one side.

```
Commanded  100.00 mm
Measured X ............ mm
Measured Y ............ mm
```

Anything within a few tenths is fine at this stage. A consistent few-percent error means a scale
factor; a difference *between* X and Y means something more interesting.

---

## Test 4 — field edges, where galvo distortion lives ⭐

This is the highest-value measurement in the project, because **both full-field lenses are
engraved 200 mm while WeCreat drives the machine to 210 mm**
([docs/06](../docs/06-modes-and-lenses.md)). This test walks the beam out past the rated field.

1. Set the square to **Width 200, Height 200**, **X 5, Y 5**.
2. **Frame.**
3. Look hard at the four sides. You are looking for **bow** — sides that curve outward (barrel)
   or inward (pincushion) rather than running straight.

```
Sides straight?      yes / no
If bowed: outward (barrel) / inward (pincushion)
Approx deviation at mid-side: ............ mm
Measured side length X: ............ mm    Y: ............ mm
Did the pointer reach all four corners without clipping?   yes / no
```

**Why it matters:** if the sides bow, the firmware's field correction is not carrying through the
G-code path. LightBurn's lens-correction UI is gated to its galvo device classes, which we are not
using, so we would have **nowhere to put a correction of our own**. That would be a much bigger
finding than mirroring, and it would change what v1.0 can honestly claim.

---

## Expected noise — do not be alarmed by these

| You will see | Why |
|---|---|
| `err:20` twice at the start of every frame | Modal setup words WeCreat's firmware does not implement (`G17`/`G40`/`G54`). GRBL rejects the line and continues. [Full diagnosis](stage3-err20-diagnosis-benchy.md) |
| `<Idle\|MPos:...\|Pn:Z>` in status | `Pn:Z` is a pin-state report, seen on every capture so far |

**If framing works correctly despite the two `err:20`s, that closes out roadmap item 1** — it
proves the errors are cosmetic rather than silently corrupting the output. Please note explicitly
whether the frame ran.

---

## Stop and call me if

- Nothing visible on Frame (Test 0) — expected possibility, not a failure
- MPos does not track commanded coordinates (Test 1)
- The pointer runs to a hard limit, or the machine alarms
- Any smell, unexpected noise, or visible light that is not the red pointer
- `err:20` appears **more than twice**, or the stream aborts rather than continuing

---

## Results

Fill in below, save the file, and tell me it is done. I will read it off the share.

```
Date:            2026-08-..
Operator:        Lee Gillie
Machine:         BENCHY / Lumos Ultra, red lens, MOPA
LightBurn:       2.1.04, Custom GCode profile, COM7

TEST 0  pointer visible on Frame?          yes / no
TEST 1  MPos tracked commanded coords?     yes / no
        MPos after G0X10Y10:               ....................
TEST 2  pointer corner:                    ....................
        => MirrorX .......  MirrorY .......
TEST 3  100 mm commanded, measured X ......... Y .........
TEST 4  200 mm commanded, measured X ......... Y .........
        sides straight?                    yes / no
        bow direction / amount:            ....................
        all four corners reached?          yes / no

err:20 count per frame:                    ....
Did the frame actually run despite them?   yes / no

Notes / anything surprising:
....................................................................
....................................................................
```

---

## What happens next

- **Tests 2–4 clean** → I regenerate both profiles with the measured values, and the same numbers
  carry to the UV profile (purple and red share a 200 mm / F290 / 10 mm prescription), then we go
  to first marks.
- **Mirroring wrong** → one-line fix in `tools/profile-spec.json`, regenerate, re-frame.
- **Sides bow** → we stop and think. That is a real finding and it changes what v1.0 promises.
- **No pointer** → we go back to the framing captures and work out which M-code MakeIt uses,
  from evidence rather than by guessing.
