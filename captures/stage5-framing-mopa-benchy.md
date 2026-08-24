# Stage 5 — MakeIt's own G-code — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **Lens:** Red · **Source:** MOPA
**Capture:** framing job (red pointer, **no beam**) · **Contributor:** Lee Gillie

> Read-only HTTP GET of files MakeIt left on the controller. Nothing was sent to the machine.
> **This is the vendor's own G-code**, so everything below is `CONFIRMED-vendor`, not inference.

## Where the files actually live

`/etc/mbtc/print.json` is **stale** — it names `/mnt/SDCARD/curve/`, which does not exist. The
real tree:

```
/mnt/SDCARD/data/framing/   framing_data.gcode   framing_mode.gcode   gcode.gc
/mnt/SDCARD/data/printing/  gcode.gc
/mnt/SDCARD/config/         heightZ.txt   greenZ.txt   lumosProMopaCalibration.txt
```

A job is assembled from two parts — a **mode preamble** and the **geometry** — concatenated into
`gcode.gc`.

## The preamble — `framing_mode.gcode`

```gcode
;wecreat 3.0.6
;canvas border: 0 0 210 210
M15S0
M107X-105Y-105
M41S0
M19S1
M42S0
M18S0Q0
M11S0.2
G90
M3S100
#headed
```

## The geometry — `framing_data.gcode`

```gcode
M4S1000
M38F
M39P
G0F480000
G1F480000
G0X71.5Y96.21F480000
G1X90.1Y96.21S0F480000
G1X90.1Y108.71
G1X71.5Y108.71
G1X71.5Y96.21
G0X71.6Y96.31
```

---

## THE FIELD SIZE IS CONFIRMED — 210 × 210 mm

```
;canvas border: 0 0 210 210
```

**MakeIt writes the working area into every job as a comment.** This was the highest-value open
question in the project — `$$` is a stub, so the controller would not report it, and it was going
to require Stage 4 measurement with calipers.

**The draft profiles' `Width: 210, Height: 210` are correct.** `CONFIRMED-vendor.`

## `M107` is confirmed as the field-origin offset

`M107X-105Y-105` — and 105 is exactly **210 ÷ 2**.

The Lumos profile carries `M107X-60Y-60` on a **116 mm** field (58 = 116 ÷ 2). The pattern holds
across both machines: **`M107` sets the origin to the centre of the field.** Previously graded
INFERRED; now **CONFIRMED-vendor**.

This also tells us the machine's native coordinate origin is the **field centre**, and MakeIt
shifts it to a corner-origin scheme for job coordinates (the square sits at X 71.5–90.1,
Y 96.21–108.71, i.e. in the middle of a 0–210 range).

## `M18` is the source select, and it is on the Ultra

```
M18S0Q0
```

`M18S0` is exactly what WeCreat's own Lumos profile labels **"1064red"** — and this capture was
taken with the **MOPA fiber source selected and the red lens fitted**. The labelling and the
hardware agree.

**But note the new `Q` parameter**, which does not appear on the Lumos. In fiber-laser usage `Q`
conventionally denotes the **Q-switch / pulse width**. If that reading holds, `M18 S<source>
Q<pulse>` would be the command that carries **MOPA pulse width** — the single parameter that
LightBurn's GRBL device class cannot express, and the one that matters most for MOPA work.

**This is currently INFERRED and needs one differential capture to settle** — see *Next* below.

## Newly observed codes

| Code | Observed | Reading | Grade |
|---|---|---|---|
| `M18` | `M18S0Q0` | **Source select.** `S0` = 1064 nm fiber, per WeCreat's own Lumos macro label. New `Q` parameter, plausibly **pulse width** | S: **CONFIRMED-vendor**; Q: **INFERRED** |
| `M107` | `M107X-105Y-105` | **Field origin offset** = half of the 210 mm field | **CONFIRMED-vendor** |
| `M15` | `M15S0` | Exhaust fan off — consistent with prior evidence, and correct for a beam-free framing job | **CONFIRMED-vendor** |
| `M19` | `M19S1` | Present in the Lumos start block as `M19S0`; here `S1`. Parameterised, meaning still unknown | UNKNOWN |
| `M3` | `M3S100` | **Standard GRBL** constant-power laser mode, S=100 | CONFIRMED |
| `M4` | `M4S1000` | **Standard GRBL** dynamic-power laser mode, S=1000. Confirms the `S_Scale: 1000` in our profiles | CONFIRMED |
| `G90` | `G90` | Standard absolute positioning | CONFIRMED |
| `M41` | `M41S0` | Unknown | UNKNOWN |
| `M42` | `M42S0` | Unknown | UNKNOWN |
| `M11` | `M11S0.2` | Unknown. A fractional argument suggests a physical quantity | UNKNOWN |
| `M38` | `M38F` | Unknown. **Bare letter, no number** | UNKNOWN |
| `M39` | `M39P` | Unknown. **Bare letter, no number** | UNKNOWN |
| `#headed` | — | Section marker, not G-code | — |

`M38F` / `M39P` are unusual: a letter parameter with no value. Possibly mode flags (`F` = frame?
`P` = pointer?).

**`M16`/`M17` do not appear** in this framing job. So the U-mode question is not settled by this
capture — but their absence from MakeIt's own output is itself informative: whatever U-mode is,
MakeIt does not need it for a framing job.

## Feed rate

`F480000` — 480,000 mm/min = **8,000 mm/s**. Galvo-class speeds are expressed in ordinary G-code
feed rate, which is why the machine can be driven this way at all.

## A 302 MB job file — and what it means for LightBurn

```
/mnt/SDCARD/data/printing/gcode.gc   302,962,036 bytes
```

A previously-run **print** job is **302 megabytes** of G-code.

This is hard evidence for the fill-throughput concern in
[01-architecture.md](../docs/01-architecture.md#2-why-a-galvo-machine-speaks-g-code). Streaming
302 MB over a 1,000,000 baud serial link is roughly **50 minutes of pure transfer**, before any
marking happens. It is why WeCreat bulk-uploads jobs to the controller's SD card instead of
streaming them.

**Implication for this project:** LightBurn's live G-code streaming will be viable for vectors and
painful-to-unusable for dense fills and photo raster. A `weburn`-style bridge that uploads a job
and lets the controller run it is not a nicety — for raster work it is likely the only workable
architecture.

## Per-lens focus heights, and a MOPA calibration file

```
/mnt/SDCARD/config/heightZ.txt   ->  43.35
/mnt/SDCARD/config/greenZ.txt    ->   8.03
/mnt/SDCARD/config/lumosProMopaCalibration.txt
    {... "basicData":{"x":20,"y":20,"width":170,"height":170,
                      "type":"5W","id":"lumosUltra-mopa"}}
```

- **Per-lens Z focus heights are stored as plain numbers.** `greenZ` (8.03) is the green K9 lens;
  `heightZ` (43.35) is the current/default. Useful once Z is characterised.
- The MOPA calibration carries **`"id":"lumosUltra-mopa"`** — so calibration is **per source**,
  and the earlier `lumosPro` in `camera.json` is confirmed as stale default data. The filename
  still says `lumosPro`, the content says `lumosUltra-mopa`.
- `"type":"5W"` and the 170 × 170 region persist here too. Since `;canvas border` gives the real
  field as 210 × 210, **the 170 × 170 is definitively camera-calibration geometry, not the laser
  field.** That ambiguity is now closed.

---

## Next — one differential capture settles the pulse-width question

This capture was labelled `mopa-pw100-frame`. Do it again with **exactly one change — a different
MOPA pulse width** — and diff `framing_mode.gcode`:

- If the `Q` value in `M18S0Q…` changes → **`Q` is the pulse width**, and MOPA pulse control can
  be expressed as custom G-code in a LightBurn profile. That would be the single biggest win
  available to this project.
- If `Q` stays `0` → pulse width lives somewhere the G-code never sees, and MOPA parameter work
  stays in MakeIt.

A second useful diff: **switch source to UV and frame again** (beam-free, no lens swap needed).
Expect `M18S1` if the Lumos labelling carries over — and watch whether `M104X1`/`M104X2` from
`/etc/mbtc/inverse_distance.json` appears.
