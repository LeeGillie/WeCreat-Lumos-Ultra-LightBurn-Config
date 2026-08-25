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
| 1 | **`err:20`** — diagnosed, likely cosmetic | 🟢 downgraded | ~5 min to confirm |
| 2 | **Stage 4 calibration** — mirroring, origin, scale | 🟡 **next** | ~20 min, no beam |
| 3 | **First marks** — power/speed behave sanely | 🟡 | ~30 min, beam |
| 4 | **Verify `M38`/`M39` survive from LightBurn** | 🟡 | ~15 min |
| 5 | **Package and publish** | ⬜ | ~1 hour |

Everything before this point — architecture, M-codes, field size, MOPA parameters, the control
latch — is **already confirmed on hardware**. What remains is small.

---

## 1. `err:20` — diagnosed 🟢

**Resolved as far as it can be without a framing pass.** Full analysis:
[`captures/stage3-err20-diagnosis-benchy.md`](captures/stage3-err20-diagnosis-benchy.md).

LightBurn's saved G-code contains exactly three lines outside MakeIt's vocabulary that could
produce two errors: `G00 G17 G40`, `G21`, and `G54`. All three are modal setup — plane select,
cutter-comp cancel, metric mode, work coordinate system. GRBL reports `error:20` and **continues
to the next line**; it does not abort. Everything that moves the head or fires the source —
`G0`, `G1`, `M4`, `M5`, `S`, `F` — is standard and accepted.

LightBurn hardcodes that block for every GCode-class device. There is no setting that removes it,
and Start G-code is appended *after* it. So the resolution is to **document it, not fix it**.

**Done when:** Stage 4 framing tracks the square accurately with the errors present. That is the
only test that distinguishes "harmless" from "silently wrong".

## 2. Stage 4 — calibration 🟡 *(no beam)*

Three values are currently unverified, and all three are wrong-looking-output risks rather than
safety risks:

- **`MirrorX` / `MirrorY`** — LightBurn's wizard defaults both `false`; the older GRBL vendor
  profile used `MirrorY: true`
- **Origin corner** — the Custom GCode class has no `CutOrigin` key at all
- **Scale** — nominal vs measured

**Method:** frame 10 / 50 / 100 / 200 mm squares with the red pointer, measure with calipers,
check orientation against the screen. Template: `captures/templates/field-calibration.md`.

**Done when:** a framed 100 mm square measures 100 mm and appears where the screen says.

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
| `weburn`-style bridge | The REST API is confirmed live. A bridge would unlock bulk upload — the answer to that 302 MB raster job — but it is a software project, not a config |
| The remaining unknown M-codes | `M11`, `M19`, `M24`, `M25`, `M26`, `M41`, `M42`, `M46`, `M57`, `M59`, `M16`/`M17` |

---

## What is already done

Worth stating, because it is most of the hard part — and none of it existed publicly before:

- Architecture confirmed on hardware: GRBL-over-serial, CH340 + Linux RNDIS gadget, no galvo board
- `Custom GCode` + `GCodeFlavor: wecreat` — LightBurn now reports **"Found WeCreat Device"**
- **Field size confirmed at 210 × 210 mm** from the vendor's own G-code
- **`M18` source select**, **`M107` origin offset**, **`M38F` frequency**, **`M39P` pulse width** —
  each confirmed by controlled differential capture
- **The MOPA wall is down**: pulse width and frequency are reachable via per-layer custom G-code
- The **control-mode latch** — undocumented anywhere, and the likely explanation for the
  community's perennial "port already in use" reports
- Camera working in LightBurn; one accessible stream, rotated, uncorrected
- Nine Ultra work modes enumerated from the shipping MakeIt bundle
- The most complete public WeCreat M-code dictionary in existence

---

## Right now

**Stage 4 framing — no beam.** Draw a 100 mm square in LightBurn, hit **Frame**, and watch where
the red pointer goes. That single test resolves `MirrorX`/`MirrorY`, the origin corner, and scale
at once, and simultaneously proves whether the two `err:20` lines matter. Template:
`captures/templates/field-calibration.md`.
