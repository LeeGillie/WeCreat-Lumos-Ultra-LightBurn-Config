# 12 — Start-of-Job Checklists

## Why this exists

MakeIt has **Field-Lens Auto Detection**. LightBurn does not, and cannot — it will not switch
device profiles because you physically swapped a lens.

That gap is not merely inconvenient on this machine. The Ultra has three lenses across two
sources at two very different wavelengths:

- Wrong lens → wrong field size → job lands somewhere unintended, out of focus.
- Wrong source → **wrong goggles**. UV goggles (190–550 nm) give you nothing against 1064 nm
  fiber, and vice versa.

LightBurn supports a per-device **start-of-job checklist**: a free-text block stored in the
device profile (`"Checklist"`, a top-level key in the `.lbdev`) that is shown before a job runs.
It is the closest thing to a software interlock available to us, and it costs nothing.

**Every profile in this repository ships with one.** Please do not strip them.

---

## The checklists

### UV — Purple lens, 210 × 210 mm

```
LENS:     PURPLE field lens installed?          (210 x 210 mm)
SOURCE:   UV (355 nm) selected?
GOGGLES:  190-550 nm UV goggles ON?
FOCUS:    Focus set for this material height?
EXHAUST:  Extraction running? (UV on wood/leather/coated goods)
BED:      Correct lens for the job -- purple is FLAT and CYLINDRICAL work
```

### UV — Green lens, K9 crystal, 70 × 70 mm

```
LENS:     GREEN field lens installed?           (70 x 70 mm ONLY)
SOURCE:   UV (355 nm) selected?
GOGGLES:  190-550 nm UV goggles ON?
FIELD:    Artwork fits within 70 x 70 mm?
NOTE:     True K9 internal 3D engraving is NOT available from LightBurn.
          This profile is for surface / 2D work through the green lens.
```

### MOPA 60 W — Red lens, 210 × 210 mm

```
LENS:     RED field lens installed?             (210 x 210 mm)
SOURCE:   MOPA fiber selected -- NOT UV?
POWER:    This is the 60 W profile. Is this a 60 W machine?
GOGGLES:  800-1100 nm fiber goggles ON?  (UV goggles do NOT protect you)
REFLECT:  Workpiece secured? Specular metal reflects the beam
EXHAUST:  Extraction running?
```

### MOPA 100 W — Red lens, 210 × 210 mm

```
LENS:     RED field lens installed?             (210 x 210 mm)
SOURCE:   MOPA fiber selected -- NOT UV?
POWER:    *** 100 WATT PROFILE ***  Is this a 100 W machine?
          A 60 W machine running 100 W settings will not behave as expected.
GOGGLES:  800-1100 nm fiber goggles ON?  (UV goggles do NOT protect you)
REFLECT:  Workpiece secured? Specular metal reflects the beam
POWER:    First run on this material? START LOW.
EXHAUST:  Extraction running?
```

### Slide Extension

```
SLIDE:    Slide Extension mounted and clear of obstructions?
TRAVEL:   Full 520 mm travel path clear -- nothing in the way of the carriage?
LENS:     Correct field lens for the source in use?
GOGGLES:  Matching wavelength goggles ON?
NOTE:     LightBurn Split Marking is galvo-only and NOT available here.
          Slide positioning is manual or macro-driven. Verify before running.
```

### Conveyor

```
BELT:     Belt clear, parts seated, load under 10 kg?
FEED:     Feed increment verified on a dry run WITHOUT the beam?
ATTEND:   Batch jobs run long. Do NOT leave unattended.
FIRE:     Extinguisher within reach? Extraction running?
LENS:     Correct field lens? GOGGLES: matching wavelength ON?
```

---

## Editing them

Checklists live in `tools/profile-spec.json` under each profile's `checklist` key.
`tools/build-profiles.ps1` writes them into the generated `.lbdev` files. Edit the spec, not the
generated profile, so the two do not drift.

To change one in LightBurn directly: Devices → select device → Edit → the checklist field.

## A note on tone

These read as shouty. That is deliberate. A checklist that people skim is worse than no
checklist, and the failure mode being guarded against — wrong goggles on a 100 W fiber laser — is
not recoverable.
