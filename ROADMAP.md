# Roadmap — how this project finishes

A project like this can expand forever: nine work modes, four accessories, two sources, three
lenses, a camera, a bridge. So v1.0 is defined **narrowly and deliberately**, and everything else
is explicitly deferred.

---

## v1.0 — the definition of done

> **Two LightBurn profiles that connect, place accurately, and mark correctly on a Lumos Ultra,
> published with honest status for every other feature.**

That is it. Not every mode, not every accessory. A configuration an Ultra owner can import and
use for real work, plus a truthful map of what is and is not possible.

### The five remaining items

| # | Item | Status | Effort |
|---|---|---|---|
| 1 | **`err:20`** — traced to `M8`/`M9`, cosmetic | ✅ **resolved** | document only |
| 2 | **Stage 4 calibration** — origin, mirroring, distortion | ✅ **DONE** | — |
| 3 | **First marks** — power/speed behave sanely | ✅ **DONE** | 15 % @ 12000 mm/min |
| 3b | **Streaming stalls on long jobs** | 🟠 **handed off — vendors own it** | test, don't solve |
| 4 | **Verify `M38`/`M39` survive from LightBurn** | 🟡 | ~15 min |
| 5 | **Package and publish** | ⬜ | ~1 hour |

> ### Item 3b changed hands on 2026-08-27
>
> It arrived on this list as a blocker. It leaves as somebody else's roadmap item.
>
> WeCreat and LightBurn are jointly implementing **job upload to internal memory** instead of
> real-time streaming, and LightBurn has a fix written for the buffer-size override that currently
> reverts to 128. Both were confirmed directly by the vendors
> ([responses](captures/vendor-responses-2026-08-27.md)).
>
> **This project cannot fix it and should stop trying.** The status report is firmware, past the
> MCU boundary; the buffer clamp is inside LightBurn. What this project *can* do is test the
> builds when they appear, measure honestly, and document the result.
>
> The arithmetic settles why upload is the right answer rather than a workaround: one real MakeIt
> job measures **222 MB and 11,276,586 lines**, which at 1,000,000 baud is roughly **39 minutes of
> pure payload** before any acknowledgement overhead
> ([measurements](captures/makeit-cache-and-absolute-gcode.md)). No buffer size makes that
> streamable.
>
> **v1.0's honest claim therefore stands as: correct geometry, correct marking, reliable vector
> work, large fills pending the upload path.** That is a shippable configuration, not a stalled one.

Everything before this point — architecture, M-codes, field size, MOPA parameters, the control
latch — is **already confirmed on hardware**. What remains is small.

---

## 1. `err:20` — RESOLVED ✅

**Cause: `M8`/`M9`, the air-assist commands.** Full analysis:
[`captures/stage4-airassist-differential.md`](captures/stage4-airassist-differential.md).

The earlier suspects — `G17`, `G40`, `G21`, `G54` — are **eliminated**: all four appear in framing
runs that produce **zero** errors. `M5` returns `ok`. `M4` is what MakeIt itself uses. `M8`/`M9` is
the only pair left, and it is exactly two commands for exactly two errors.

**It cannot be switched off.** Turning air assist off in the layer swaps `M8` for `M9` rather than
removing it — LightBurn emits two air-assist codes either way.

**It does not matter.** GRBL reports `error:20` and continues to the next line. Stage 4 proved
geometry is correct with those errors present. The resolution is to **document it** so Ultra owners
do not mistake it for a broken setup.

## 2. Stage 4 — calibration ✅ DONE *(no beam)*

| Question | Answer | Evidence |
|---|---|---|
| Origin corner | **top-left** — set via the Origin 2×2 widget, which is where this device class puts it | [Test 2](captures/stage4-mirror-origin-benchy.md), confirmed in two corners |
| Coordinate mapping | `MPos = commanded − 105` on both axes — the `M107X-105Y-105` field-centre origin, seen from LightBurn's side | same |
| Field distortion at 200 mm | **none detectable** — bow under 0.2 mm, probably under 0.1 mm | [Test 4](captures/stage4-test4-field-distortion-benchy.md) |
| Scale | 1:1, unmeasured but agreed by three independent sources | [Test 3 notes](captures/STAGE4-TEST3-SCALE.md) |

The distortion result is the significant one: **the controller's field correction applies to G-code
motion**, not only to MakeIt's own jobs. LightBurn gates lens correction to galvo device classes we
are not using, so had it been otherwise there would have been nowhere to put a fix.

<details>
<summary>Original plan, kept for reference</summary>

- **`MirrorX` / `MirrorY`** — LightBurn's wizard defaults both `false`; the older GRBL vendor
  profile used `MirrorY: true`
- **Origin corner** — the Custom GCode class has no `CutOrigin` key at all
- **Scale** — nominal vs measured

**Method:** frame 10 / 50 / 100 / 200 mm squares with the red pointer, measure with calipers,
check orientation against the screen. Template: `captures/templates/field-calibration.md`.

**Test the corners, not just the centre.** This is a galvo — two mirrors sweeping a beam across
an f-theta lens — so any residual barrel or pincushion distortion appears at the *edges* of a
210 mm field and is invisible in the middle. A 200 mm square is therefore the diagnostic one:
if its sides bow, the firmware's own field correction is not carrying, and that is a much bigger
problem than mirroring. LightBurn's lens-correction UI is gated to its galvo device classes and
is not available to us here, so we would have nowhere to put a correction of our own.

**Calibrate once, not twice.** The purple and red lenses carry the *same* prescription —
200 mm field, 290 mm focal length, 10 mm aperture, differing only in design wavelength
([docs/06](docs/06-modes-and-lenses.md)). So the mirroring, origin and scale resolved with the red
lens should transfer to the UV profile unchanged, and the captured `G0Z47.8` focus height should
hold for both. Worth a spot-check with the purple lens before shipping, but not a second full
calibration.

**Done when:** a framed 100 mm square measures 100 mm and appears where the screen says, and a
200 mm square has straight sides.

</details>

## 3. First marks 🟡 *(beam — red lens fitted, 800–1100 nm goggles)*

Lowest power that marks, on metal scrap. Confirm `S` scales sensibly against `S_Scale: 1000`, and
that speed behaves. A LightBurn Material Test grid is the efficient version.

**Done when:** power and speed produce predictable, repeatable results.

## 4. Verify the MOPA parameters round-trip 🟡

`M38F`/`M39P` are confirmed as *WeCreat's* output. Emitting them *from* LightBurn is untested.

**Method:** put `M18S0 / M38F75 / M39P200` in a layer's custom G-code
([docs/14](docs/14-mopa-parameters-in-lightburn.md)), run a small job, then read the G-code back
off the controller with `tools/stage5-jobfile-grab.ps1` and confirm the codes survived.

**Done when:** the codes appear in the controller's copy, and two different pulse widths visibly
differ on metal.

## 5. Package and publish ⬜

- Regenerate profiles with the calibrated values
- Build a single `WeCreat-Lumos-Ultra.lbzip` User Bundle (all profiles, ready to import once)
- Fill in a starter material library from the Stage 3 tests — **only values actually run**
- Final pass over the feature inventory so every row is current
- `gh repo create` → public → push
- Post it to the LightBurn forum's WeCreat category, which today contains **no Lumos or Lumos
  Ultra topic at all**

---

## Explicitly deferred to v1.1+

Not failures — scope control. Each is genuinely useful and none blocks a usable configuration.

| Deferred | Why |
|---|---|
| Rotary Pro | Needs the hardware fitted and its own differential capture. The Custom GCode device class has no `rotary*` keys, so this needs investigation rather than configuration |
| Slide Extension | LightBurn's Split Marking is galvo-only. Manual tiling may work; unproven |
| AutoFlow Conveyor | Same, plus the vendor quotes three different working areas |
| Green lens / K9 | 2D surface marking may work; 3D internal is MakeIt-only |
| Camera alignment | Camera *works*; full alignment calibration is a separate exercise |
| `weburn`-style bridge | **Dropped, and for a good reason.** The REST API is confirmed live and the job format is confirmed to be plain G-code — but WeCreat and LightBurn are building the official upload path, and LightBurn has no plugin hook to route jobs through a third-party bridge anyway. Characterise the endpoint for their benefit; do not build a parallel one |
| The remaining unknown M-codes | `M11`, `M19`, `M24`, `M25`, `M26`, `M41`, `M42`, `M46`, `M57`, `M59`, `M16`/`M17`. `M46` now has a second data point — `M46A1B0` in a flat job against `M46A0.9764B20` in a deep emboss, which reads as a scale-and-offset pair |

---

## What is already done

Worth stating, because it is most of the hard part — and none of it existed publicly before:

- Architecture confirmed on hardware: GRBL-over-serial, CH340 + Linux RNDIS gadget. The machine
  **is** a galvo — nothing moves in the work area — but it exposes no galvo control board to the
  host. The controller accepts G-code and does the scanner driving itself
- `Custom GCode` + `GCodeFlavor: wecreat` — LightBurn now reports **"Found WeCreat Device"**
- **Field size confirmed at 210 × 210 mm** from the vendor's own G-code — while all three lenses,
  read off the glass, are rated 200 mm (70 mm for crystal). The machine is scanned past its lenses
- **All three lens part numbers recovered from the hardware**, including **1064 nm confirmed** for
  the MOPA source, which WeCreat has never published. UV and MOPA optics are the same prescription
- **`M18` source select**, **`M107` origin offset**, **`M38F` frequency**, **`M39P` pulse width** —
  each confirmed by controlled differential capture
- **The MOPA wall is down**: pulse width and frequency are reachable via per-layer custom G-code
- The **control-mode latch** — undocumented anywhere, and the likely explanation for the
  community's perennial "port already in use" reports
- Camera working in LightBurn via its **built-in WeCreat preset** — whose URL,
  `http://192.168.42.1:8080/camera/take_photo`, is character-for-character the endpoint this
  project reverse-engineered by probing. Vendor tooling confirming our architecture
- **Stage 4 complete**: origin resolved, coordinate mapping confirmed against `M107`, and **no
  detectable field distortion at 200 mm** — the firmware's galvo correction reaches G-code jobs
- **`err:20` traced to `M8`/`M9`** by single-variable differential, and shown to be harmless
- Nine Ultra work modes enumerated from the shipping MakeIt bundle
- The most complete public WeCreat M-code dictionary in existence

---

## Right now

The streaming investigation consumed a fortnight and became the headline. It was never the
project. **The project is a configuration covering every source, lens and accessory on this
machine** — and most of that is untouched while none of it waits on the upload path.

### Housekeeping first — two things this project owes itself

1. **A clean drift measurement.** The published 2.30 mm figure came from a run contaminated by
   Pause/Resume. Run a fill that stands a real chance of *completing* — Offset Fill, or a small
   dense one — never touch Pause/Resume, and compare the final `MPos` against the declared bounds.
   Either it confirms the mechanism properly or it retires a claim this project should not be
   making. Both outcomes are worth having, and the second is worth more.
2. **Blank the `Air On` / `Air Off` templates** so `M8`/`M9` leave the stream entirely. Known,
   trivial, still not done.

### Then the actual work, in order of value

| | Why now |
|---|---|
| **`Enable Q-Pulse Options`** | The firmware side is settled: WeCreat's own generator emits **282 `M38`/`M39` pairs inside one job** ([evidence](captures/makeit-cache-and-absolute-gcode.md)). If this toggle exposes per-layer pulse control, MOPA becomes a first-class LightBurn parameter and [docs/09](docs/09-k9-and-mopa-limits.md) needs rewriting |
| **Green lens / K9 2D** | Surface marking on the crystal lens is plausible today and completely untested. 3D internal remains MakeIt-only |
| **Rotary Pro** | Needs the hardware fitted and a differential capture. The Custom GCode class exposes no `rotary*` keys, so this is investigation before configuration |
| **Camera alignment** | The camera *connects*. Full alignment calibration is a separate, self-contained exercise that needs no beam |
| **Slide / conveyor** | Manual tiling, unproven. The vendor quotes three different working areas for the conveyor, which is its own small research problem |
| **`S0` on `Rapid Move`** | Should kill the travel scar without depending on `$32` laser mode, which this firmware will not read back |

### Waiting on others — track, do not chase

- **Firmware version.** A LightBurn dev reports drift-free relative fills on their Ultra and
  suspects an unreleased build. This machine is on `ver 000240`. If newer firmware exists, some of
  what is documented here may already be obsolete
- **The buffer-size override fix.** Once the value sticks, test below 127 — a specific,
  evidence-backed experiment rather than a guess
- **The upload test builds.** Volunteer, test, document
