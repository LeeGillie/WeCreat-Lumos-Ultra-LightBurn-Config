# Stage 5 — UV vs MOPA differential, and a real print preamble — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie

> All read-only. Framing captures use the red pointer only — no beam. The print preamble was read
> from a job MakeIt had already run. **This is the vendor's own G-code.**

## The differential — one variable changed, source only

| | **MOPA** (red lens) | **UV** | Changed? |
|---|---|---|---|
| | `M15S0` | `M15S0` | |
| | `M107X-105Y-105` | `M107X-105Y-105` | |
| | `M41S0` | `M41S1` | **yes** |
| | `M19S1` | `M19S0` | **yes** |
| | `M42S0` | *absent* | **MOPA only** |
| | `M18S0Q0` | `M18S1` | **yes — and `Q` is MOPA-only** |
| | `M11S0.2` | `M11S0.2` | |
| | `G90` `M3S100` | `G90` `M3S100` | |
| geometry | `M4S1000` `M38F` `M39P` | `M4S1000` `M38F` | **`M39P` MOPA only** |

### `M18` is the source select — CONFIRMED

`M18S0` = MOPA fiber · `M18S1` = UV.

This matches WeCreat's own Lumos macro labels exactly (`M18S0` = "1064red", `M18S1` = "455Blue").
The code carries across the family; only the *identity* of source 1 differs — a 455 nm blue diode
on the Lumos, the 355 nm UV source on the Ultra. **`CONFIRMED-vendor`.**

### Four codes are MOPA-specific

`M42`, `M39P`, the `Q` parameter on `M18`, and a flipped `M41`/`M19` pair. Whatever configures the
fiber source lives in these.

---

## The real print job preamble — the important half

A previously-run **raster** job (`/mnt/SDCARD/data/printing/gcode.gc`, 302 MB — we fetched the
first 147 KB):

```gcode
;wecreat 3.0.6
;canvas border: 0 0 210 210
M15S1                  ; exhaust ON (framing had S0)
M107X-105Y-105
M57A450B30             ; Lumos used A130 B120 - job- or machine-specific
M19S0
M18S0                  ; MOPA - and NO Q on a real job
G90
G4P1                   ; dwell
M46A0.9764B20
G0X105Y105             ; move to the exact centre of the 210 field
M25S1
M26S1
M24S15
M15S70                 ; exhaust at 70 - M15 TAKES A RANGE, not just on/off
M59A-1000B50
M1S0                   ; "BMP" per the Lumos macro label - raster mode
M4S1000                ; GRBL dynamic power, S scale 1000
M11S0.08               ; framing used S0.2
G0Z47.8                ; ABSOLUTE Z FOCUS MOVE
M38F75                 ; F75  <- has a VALUE here; framing had a bare M38F
M39P200                ; P200 <- has a VALUE here; framing had a bare M39P
G0F15000
G1F120000
G0X112.985Y85.947F300000
G1X113.876Y86.401S0
G1X114.025Y86.477S78
G1X114.144Y86.537S99
...                    ; per-segment S values, 0-900, against M4S1000
```

## What this changes

### 1. `M38F` / `M39P` are the strongest MOPA-parameter candidates yet

In the **framing** job they appear bare — `M38F`, `M39P`, no values. In a **real print** job they
carry numbers: **`M38F75`** and **`M39P200`**.

`F` and `P` on a MOPA fiber source, with values of 75 and 200, read naturally as
**frequency (75 kHz)** and **pulse width (200 ns)** — both squarely in normal MOPA ranges.

**If that holds, MOPA frequency and pulse width ARE expressible in G-code** — which means they can
be delivered from LightBurn as per-layer custom G-code or macros, despite LightBurn's GRBL device
class having no native field for them. That is the single biggest thing this project could
deliver. **Graded INFERRED (strong).**

It also explains why `Q` was `0` on the framing capture and absent from the print job: `Q` is not
where the pulse width lives.

### 2. Z focus is a plain `G0 Z`

`G0Z47.8`, against a stored default of `43.35` in `/mnt/SDCARD/config/heightZ.txt`. Focus height
is ordinary absolute-Z G-code — **so LightBurn's Z support can drive it**, once the direction and
datum are established. Our profiles currently ship `EnableZ: false`; that can change.

### 3. `M15` is not a binary fan switch

`M15S0` (framing), `M15S1` then `M15S70` (print). It takes a **range** — almost certainly a fan
speed percentage. Prior evidence had it as simple on/off; that was wrong.

### 4. `M1S0` confirms the content-mode switch

Matches WeCreat's own Lumos macro label "BMP" for `M1S0`. This 302 MB job is raster, and it is
flagged as such. `M1S1` = "svg"/vector.

### 5. Power really is 0–1000

Per-segment `S` values run 0–900 under `M4S1000`. **`S_Scale: 1000` in our draft profiles is
correct.** `CONFIRMED-vendor.`

### 6. Separate rapid and cutting feed rates

`G0F15000` / `G1F120000`, with a `G0…F300000` rapid. Framing used a flat `F480000`.

## New unknowns, honestly recorded

| Code | Observed | Notes |
|---|---|---|
| `M57` | `A450B30` (Ultra print), `A130B120` (Lumos profile) | Two samples now, still unknown |
| `M46` | `A0.9764B20` | `A` near 1.0 reads like a scale factor |
| `M59` | `A-1000B50` | |
| `M24` | `S15` | |
| `M25` / `M26` | `S1` | |
| `M41` | `S0` MOPA / `S1` UV | Switches with source — lens or beam path? |
| `M19` | `S1` MOPA / `S0` UV | Also switches with source |
| `M42` | `S0`, MOPA only | |
| `M11` | `S0.2` framing / `S0.08` print | Fractional — a physical quantity |
| `G4P1` | dwell | Standard G-code |

---

## Next — the experiment that settles MOPA control

Two **real** MOPA jobs (not framing — framing emits the codes bare), changing **exactly one
parameter**:

1. Job A at one frequency/pulse width → grab, label `mopa-f75-p200`
2. Job B with **only the pulse width changed** → grab, label `mopa-f75-p400`

If `M39P` tracks the pulse width and `M38F` tracks the frequency, **MOPA parameter control in
LightBurn becomes possible** via per-layer custom G-code. That would overturn the central
limitation documented in
[09-k9-and-mopa-limits.md](../docs/09-k9-and-mopa-limits.md).

Requires the beam: red lens (already fitted), 800–1100 nm goggles, metal scrap, low power.
