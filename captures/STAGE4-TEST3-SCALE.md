# Stage 4, Test 3 — scale, revised

**Supersedes Test 3 in [STAGE4-RUNBOOK.md](STAGE4-RUNBOOK.md).** The original said "frame a
100 mm square and measure it with calipers". That was written before we knew two things, and it
does not survive either of them.

## Why the original procedure is wrong

**Calipers measure objects. A frame is light.** There is nothing physical on the bed to put jaws
around — you would be trying to measure a red dot's path in mid-air, by eye, to a tenth of a
millimetre.

**And framing is single-pass** ([see the note](stage4-mirror-origin-benchy.md)), so there is not
even a persistent outline to eyeball. There is a dot travelling at 13 mm/s and then nothing.

## ⚠️ The dependency nobody should skip: Z

On a galvo, **field size is proportional to working distance.** The beam sweeps an angle; how far
that angle travels depends on how far the surface is from the lens. Measure at the wrong height
and you will measure the wrong scale — and it will look like a clean, believable, entirely wrong
number.

Relevant known values:

| Source | Value |
|---|---|
| MakeIt's marking preamble | `G0Z47.8` |
| `/mnt/SDCARD/config/heightZ.txt` | `43.35` |
| `/mnt/SDCARD/config/greenZ.txt` | `8.03` (green/crystal lens) |
| Red lens focal length | 290 mm |

LightBurn is **not** driving Z — `Enable Z Axis` is off in Device Settings — so Z is wherever the
machine was last left. **Whatever surface you measure on must be at the machine's correct focus
height**, set by the machine's normal focusing procedure, or the result is meaningless.

This is also why a scale number measured at one height does not transfer to work at another.

## Method A — two-point pencil marks *(beam-free, recommended)*

Measures the distance the beam actually travels for a commanded 100 mm, using marks you can put
calipers on.

1. Tape a sheet of paper or card to the bed, flat, **at correct focus height**.
2. Draw a small square, **2 × 2 mm**. Set it to **X 55, Y 105**.
3. **Frame.** Pencil-mark the centre of where the dot sits. Frame repeatedly if you need more
   than one pass to place the mark confidently — it returns to the same place every time.
4. Change position to **X 155, Y 105**. Frame. Mark again.
5. **Measure between the two pencil marks with calipers. Expect 100.00 mm.**
6. Repeat vertically: **X 105, Y 55** and **X 105, Y 155**. Expect 100.00 mm.

```
Commanded X separation  100.00 mm     measured .......... mm
Commanded Y separation  100.00 mm     measured .......... mm
Paper at correct focus height?         yes / no
```

Two marks 100 mm apart is a far better measurement than one square's edge, because the pencil
marks are physical, permanent, and the caliper jaws have something real to sit on.

## Method B — mark it *(definitive, needs the beam)*

The only fully trustworthy scale check is to **mark a 100 mm square on material and measure the
mark**. That belongs to Stage 3 (first marks), not here, and needs the red lens, 800–1100 nm
goggles and metal scrap.

If Method A comes out clean, Method B becomes a confirmation rather than a discovery.

## How much does this matter? Less than it looks

Evidence already in hand that scale is 1:1:

- `MPos` tracks commanded coordinates **exactly**, at two independent positions, with a constant
  −105 offset and no multiplier ([capture](stage4-mirror-origin-benchy.md))
- MakeIt's own G-code works in the same 0–210 coordinate space, with the same `M107X-105Y-105`
  origin offset
- Our profile's `Width: 210, Height: 210` is `CONFIRMED-vendor` from `;canvas border: 0 0 210 210`

A gross scale error would have to survive all three. **Test 3 is a sanity check, not a discovery
exercise** — and any real error will announce itself immediately at first marks.

> **If you are short on time, skip to Test 4.** Test 4 can find something we do not already know;
> Test 3 mostly confirms something three independent sources already agree on.
