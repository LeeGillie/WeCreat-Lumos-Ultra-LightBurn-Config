# 06 — Work Modes, Field Lenses and Working Areas

## The nine Ultra work modes

Enumerated from the shipping **MakeIt! 3.0.6** application bundle, which contains a
`lumosUltraWorkMode/` asset folder distinct from the generic `workMode/` folder. This is the
vendor's own mode list for *this specific machine*. **CONFIRMED-vendor** — method in
[11-makeit-internals.md](11-makeit-internals.md).

| MakeIt asset | Mode | Requires |
|---|---|---|
| `plane-mode` | Flat surface engraving | — |
| `cylinder-mode` | Cylindrical / rotary engraving | Rotary Pro |
| `emboss-mode` | Relief / depth-map engraving | — |
| `crystal-mode` | K9 crystal internal engraving | Green lens |
| `crystal-mode3D` | K9 volumetric 3D internal engraving | Green lens |
| `autoslider-mode` | Slide Extension, flat work | Slide Extension |
| `autosliderCylinder-mode` | Slide + rotary, long cylinders | Slide + Rotary |
| `conveyorbelt-mode` | AutoFlow conveyor batch feeding | Conveyor |
| `conveyorBeltSlide-mode` | Conveyor + slide combined | Conveyor + Slide |

The generic (non-Ultra) MakeIt mode set additionally contains `baseplate-mode`, `curve-mode` and
`manualhand-mode`. These have no Ultra-specific asset and may or may not apply.

Two observations worth drawing out:

1. **`crystal-mode` and `crystal-mode3D` are separate modes.** That supports the hypothesis that
   flat/2D internal marking is a distinct, simpler operation from volumetric 3D — and therefore
   that 2D crystal work is the more plausible thing to reach from LightBurn. Worth testing
   (Stage 11) even though 3D almost certainly is not.
2. **The slide and conveyor each have a "plain" and a "combined" mode.** So the controller
   distinguishes slide-alone from slide+rotary and conveyor-alone from conveyor+slide. Four
   distinct motion configurations to characterise, not two.

## Field lenses

WeCreat's own names for the three, from the product photography: **UV**, **CRYSTAL**, **MOPA**.
The anodising colour is a keying aid, not a wavelength.

All three read off the glass. **Evidence grade: CONFIRMED-hardware.**

| Lens | Vendor name | Purpose | λ | Field | Focal | Aperture | Marked part number |
|---|---|---|---|---|---|---|---|
| **Purple** | UV | General UV — flat *and* cylindrical | 355 nm | 200 mm | 290 mm | 10 mm | `H YL-355-200-F290-FS10-D` · SN 26031154 |
| **Green** | CRYSTAL | K9 crystal internal engraving | 355 nm | 70 mm | 100 mm | 10 mm | `JG-SL-355-100-70G-10` · SN 26041005915 |
| **Red** | MOPA | MOPA fiber (60 W and 100 W share it) | **1064 nm** | 200 mm | 290 mm | 10 mm | `H SL-1064-200-F290-D10-C` · SN 260513114 |

> **Revision suffixes vary.** A `-C` purple lens (`…FS10-C`, SN 25111011) appears in WeCreat's
> product photography; the unit in our test machine is `-D` (SN 26031154). Same optical
> prescription, different revision letter. Do not treat the trailing letter as significant when
> matching a lens to this table.

### Decoding the purple lens marking

```
H  YL - 355 - 200 - F290 - FS10 - D        SN: 26031154
        │     │     │      │       └─ coating / variant
        │     │     │      └───────── FS10  = 10 mm input beam aperture
        │     │     └──────────────── F290  = 290 mm focal length
        │     └────────────────────── 200   = 200 mm scan field
        └──────────────────────────── 355   = 355 nm design wavelength (UV)
```

Internally consistent: an f-theta at f = 290 mm sweeping the ±20° typical of a
galvo scanner gives 2 × 290 × tan-ish(20°) ≈ 200 mm of field. The optics agree
with the label.

### Decoding the red (MOPA) lens marking

```
H  SL - 1064 - 200 - F290 - D10 - C        SN: 260513114
        │      │     │      │      └─ coating / variant
        │      │     │      └──────── D10   = 10 mm input beam aperture
        │      │     └─────────────── F290  = 290 mm focal length
        │      └───────────────────── 200   = 200 mm scan field
        └──────────────────────────── 1064  = 1064 nm design wavelength (IR)
```

> ### ✅ 1064 nm is now confirmed, not reported
>
> Every public source for the Ultra's fiber wavelength has been third-party inference —
> **WeCreat does not publish it.** This lens is engraved `1064`. `SAFETY.md` previously carried
> the hedge "1064 nm (third-party reports)"; that hedge is now retired.
>
> It also matches WeCreat's own macro label `M18S0` = **"1064red"**
> ([docs/04](04-mcode-dictionary.md)), which we had from the Lumos profile. Vendor label and
> vendor glass agree.

### 🎯 The two full-field lenses are optically identical

Set the purple and red markings side by side:

```
H YL - 355  - 200 - F290 - FS10 - D      UV
H SL - 1064 - 200 - F290 - D10  - C      MOPA
        ^^^^   ^^^   ^^^^   ^^^
     wavelength ONLY difference that matters
```

**Same 200 mm field. Same 290 mm focal length. Same 10 mm aperture.** The UV and MOPA optics are
the same prescription built for different wavelengths.

That is the single most useful thing on this page, because it means:

| Consequence | Why |
|---|---|
| **One field calibration serves both profiles** | Same field, same focal length, same scan angle. Whatever `MirrorX`/`MirrorY`/origin/scale we resolve in Stage 4 with the red lens should transfer to the purple profile unchanged |
| **Same working distance** | The captured `G0Z47.8` focus height should hold for both. Different sources, same geometry |
| **The profiles differ only in source and parameters** | `M18S1` vs `M18S0`, plus the MOPA-only `M38F`/`M39P`. Not in field geometry |
| **Green is the odd one out** | 100 mm focal, 70 mm field — a genuinely different optic needing its own calibration, if we ever get there |

This still needs proving on hardware — do not ship a purple profile calibrated only against red.
But it means Stage 4 is one calibration exercise rather than two, and it explains why WeCreat can
treat lens swapping as a simple identity read.

### Decoding the green (CRYSTAL) lens marking

```
JG-SL - 355 - 100 - 70G - 10        SN: 26041005915
  │      │     │     │     └─ 10 mm input beam aperture
  │      │     │     └─────── 70 mm field  (matches the 70 x 70 mm spec)
  │      │     └───────────── 100 mm focal length
  │      └─────────────────── 355 nm design wavelength — UV, same as purple
  └────────────────────────── different supplier prefix from the purple lens
```

Sanity check: f = 100 mm at ±20° gives ≈ 73 mm of field. That lands on the
vendor's 70 × 70 mm crystal working area, so the reading holds together.

**Caveat — the two suppliers order their fields differently.** The purple lens
is `YL`, the green is `JG-SL`, and the purple puts field before focal length
(`200-F290`) while the green appears to put focal length before field
(`100-70G`). The `355` and the `10` are unambiguous; the `100` / `70G` split is
**INFERRED** from the field-size match, not from a datasheet.

### What the green lens confirms

> **The green lens is a 355 nm optic.** The CRYSTAL lens runs on the *same UV
> source* as the purple one — the colour is keying, not wavelength.

This was previously inferred from `M18S1` selecting UV for both modes
([docs/04](04-mcode-dictionary.md)). It is now **CONFIRMED-hardware** by the
glass itself, which upgrades two things:

1. **Eyewear.** Purple and green share the 190–550 nm UV requirement. Only the
   red lens moves you to 800–1100 nm. `SAFETY.md` and
   [docs/12](12-checklists.md) already said this; they were right.
2. **All three lenses are 10 mm input aperture.** They mount on a common galvo
   output beam, which is why field-lens auto-detection can be a simple identity
   read rather than an optical re-alignment.

Also worth noting: the crystal lens's short 100 mm focal length is what buys the
deep focal *travel* needed to sweep a focus through a 135 mm crystal — and what
costs it the field, at 70 mm versus the purple lens's 200 mm.

> ### ⚠️ Both full-field lenses are rated for 200 mm. The machine is driven to 210 mm.
>
> The vendor's own G-code declares `;canvas border: 0 0 210 210` and centres at
> `G0X105Y105`, and WeCreat's spec sheet says 210 × 210 mm. But **both** the
> purple and the red lens are engraved **200**. The machine is being scanned
> roughly 5 % past its lenses' rated field — on UV and on MOPA alike, so this is
> not a quirk of one optic.
>
> Outside the rated field an f-theta's spot grows, its focal plane walks, and —
> critically — the manufacturer's distortion correction is no longer
> characterised. Marks near the extreme edge may be geometrically off, out of
> focus, or both, and no amount of LightBurn configuration fixes that.
>
> **This is not a bug we introduced and not one we can fix.** It is a property of
> the machine that Ultra owners should know about. It also makes the Stage 4
> 200 mm framing square the single most informative test in this project: it
> walks the beam right out to the edge of the rated field, where any problem
> will show.
>
> Unverified: whether the "reviewer-reported 200 mm focal length" figures below
> were always this scan-field number misread as focal length. Given this lens is
> f = 290 mm with a 200 mm field, that looks likely — and if so the same
> confusion probably applies to the red lens.

Vendor "Working area" spec row, verbatim:

> Standard Work Area: 210*210mm / Crystal Inner Engraving: 70*70mm / Slide Extension:
> 520mm*183mm / Auto Conveyor: 1000mm*200mm (Batch Feeding)

Max processing height row: **Surface Engraving 130 mm / Inner Engraving 160 mm.** Note the mild
inconsistency with the Kickstarter FAQ's 135 mm crystal engraving depth — 135 mm is plausibly the
usable engraving depth and 160 mm the mechanical clearance.

### Lens auto-detection

WeCreat advertises **Field-Lens Auto Detection**, and MakeIt uses it. LightBurn cannot: it will
not switch device profiles because you physically swapped a lens.

**This is a safety issue, not just an inconvenience.** Marking with the wrong profile means the
wrong field size, and — if the source also differs — potentially the wrong goggles.

Our mitigation is LightBurn's per-device **Checklist** (a top-level `"Checklist"` string in the
`.lbdev`), which pops before every job. See [12-checklists.md](12-checklists.md).

## Why separate profiles rather than one

LightBurn's own guidance for interchangeable optics is one device profile per lens, because
field dimensions and calibration differ. For this machine the argument is even simpler: the
working area is different (210 vs 70), and on a GRBL device the workspace size *is* the profile.

Splitting 60 W and 100 W MOPA into separate profiles despite identical geometry buys one thing:
**separate material libraries and separate checklists**. A 100 W setting run on a 60 W machine
underperforms; a 60 W setting run on a 100 W machine over-drives. Keeping them apart is worth a
duplicate profile.

## Profile matrix

| Profile | Source | Lens | Width × Height |
|---|---|---|---|
| `WeCreat-Lumos-Ultra-UV-Purple-210` | 6 W UV | Purple | 210 × 210 |
| `WeCreat-Lumos-Ultra-UV-Green-K9-70` | 6 W UV | Green | 70 × 70 |
| `WeCreat-Lumos-Ultra-MOPA60-Red-210` | 60 W MOPA | Red | 210 × 210 |
| `WeCreat-Lumos-Ultra-MOPA100-Red-210` | 100 W MOPA | Red | 210 × 210 |
| `WeCreat-Lumos-Ultra-Slide-520x183` | any | any | 520 × 183 |
| `WeCreat-Lumos-Ultra-Conveyor-206` | any | any | 206 × 206 |

The last two are **speculative** — they assume the machine can be told to treat a larger area as
its workspace, which is unproven. They exist so that a contributor with the hardware has
something to test rather than something to build.

Reported working areas for the conveyor disagree across WeCreat's own pages: 206 × 206 mm per
cycle (Kickstarter FAQ), 200 × 500 mm (conveyor product page), 1000 × 200 mm (main spec table).
Most plausible reading — 206 × 206 mm is the per-pass galvo field on the belt, 500 mm the initial
load area, 1000 mm the total fed length — but that is **INFERRED**, not confirmed.
