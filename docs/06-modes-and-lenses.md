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

| Lens | Purpose | Working area | Marked part number | Notes |
|---|---|---|---|---|
| **Purple** | General UV — flat *and* cylindrical | 210 × 210 mm claimed | `H YL-355-200-F290-FS10-C` | **CONFIRMED-hardware.** 355 nm, 200 mm scan field, **290 mm focal length**, 10 mm input aperture |
| **Green** | K9 crystal internal engraving | 70 × 70 mm | not yet photographed | Volume 70 × 70 × 135 mm. Reviewer-reported 70 mm focal length |
| **Red** | MOPA fiber (60 W and 100 W share it) | 210 × 210 mm claimed | not yet photographed | Expect a 1064 nm equivalent. Wanted: a photo of the engraved ring |

### Decoding the purple lens marking

```
H  YL - 355 - 200 - F290 - FS10 - C        SN: 25111011
        │     │     │      │       └─ coating / variant
        │     │     │      └───────── FS10  = 10 mm input beam aperture
        │     │     └──────────────── F290  = 290 mm focal length
        │     └────────────────────── 200   = 200 mm scan field
        └──────────────────────────── 355   = 355 nm design wavelength (UV)
```

Internally consistent: an f-theta at f = 290 mm sweeping the ±20° typical of a
galvo scanner gives 2 × 290 × tan-ish(20°) ≈ 200 mm of field. The optics agree
with the label.

> ### ⚠️ The lens is rated for 200 mm. The machine is driven to 210 mm.
>
> The vendor's own G-code declares `;canvas border: 0 0 210 210` and centres at
> `G0X105Y105`, and WeCreat's spec sheet says 210 × 210 mm. But this lens is
> engraved **200**. The machine is being scanned roughly 5 % past its lens's
> rated field.
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
