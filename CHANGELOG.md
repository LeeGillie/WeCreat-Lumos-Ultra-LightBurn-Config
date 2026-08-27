# Changelog

## [0.2.0] — 2026-08-27 — Confirmed on hardware, published, and both vendors engaged

The version where the project stopped being research and started being a configuration that marks
metal. Everything in 0.1.0 was inference from files; most of it is now confirmed on a physical
machine, and two claims turned out to be wrong.

### Confirmed on hardware

- **Architecture.** A physical Lumos Ultra enumerates as a CH340 serial bridge plus a Linux RNDIS
  gadget, with **no galvo control board**. It *is* a galvo — nothing moves in the work area — but
  it exposes only G-code to the host.
- **Geometry.** Field **210 × 210 mm**, origin **top-left**, `MPos = commanded − 105` matching the
  machine's own `M107X-105Y-105`. **No detectable field distortion at 200 mm** (< 0.2 mm), which
  matters because LightBurn gates lens correction to galvo device classes we cannot use.
- **First marks**, 2026-08-25 — 15 % @ 12000 mm/min on black anodized aluminium.
- **`M18` source select is required to mark at all.** Without it the machine streams a job and
  marks nothing at any power. It belongs in the **User Start Script**; `StartGCode` is ignored by
  this device class.
- **`err:20` traced to `M8`** by single-variable differential, and shown to be harmless.
- **All three lens part numbers, read off the glass** — including **1064 nm confirmed** for the
  MOPA source, which WeCreat has never published.
- **MOPA frequency and pulse width are reachable**, and **change mid-job** — 282 `M38` and 282
  `M39` statements in a single vendor emboss job.
- **The controller filesystem** — Allwinner R528 running OpenWrt, jobs at
  `/mnt/SDCARD/data/printing/gcode.gc`, and three previously unknown M-codes (`M44`, `M101`,
  `M104`).
- **MakeIt stages its complete job on the PC**, so WeCreat's generator output can be read with no
  machine access at all.

### The streaming defect — found, diagnosed, handed off

Long jobs stall and fills drift. The controller's GRBL status report is partly fabricated: `MPos`
is live and correct, but the state field is **always `Idle`** and `FS` always `0,0`.

Reported to both vendors; both replied within a day of publication:

- **LightBurn** confirmed the machine **drops moves at a buffer of ≥127**, and that the
  buffer-size override is a separate bug with a fix already written.
- **WeCreat** confirmed "almost all" findings, and that they and LightBurn are jointly
  implementing **job upload to internal memory** instead of streaming.

Measured scale that settles why upload is the right architecture: one real MakeIt job is **222 MB
and 11,276,586 lines** — roughly **39 minutes of pure payload** at 1,000,000 baud before any
acknowledgement overhead.

**This is no longer this project's problem to solve, only to test and document.**

### Corrections

Recorded rather than quietly edited, in keeping with how this repo handles its mistakes.

- **UV spot size.** WeCreat's published `0.0019 mm` was wrong and **WeCreat corrected it** — the
  actual figure is **6–8 μm**; 1.9 μm was motion accuracy. `docs/02` A1 updated.
- **"Buffer size turns out not to be a lever at all"** — wrong. It is exactly the lever; the
  correct conclusion was the narrower *"the value cannot currently be set."*
- **A head-collision warning** was issued for a machine with no moving head. Retracted.
- **`MPos` called a stub** — it is live and correct. Only the state field is fabricated.
- **A device identified by DisplayName** rather than by its emitted G-code header, causing a
  differential to be run across two different device classes. Cost an afternoon; written up.
- **The published 2.30 mm drift figure is contaminated** — that run used Pause/Resume repeatedly.
  A clean measurement is owed and the claim is flagged in place until it exists.

### Added

- `docs/13` test-machine setup, `docs/14` MOPA parameters in LightBurn,
  `docs/15` viewing windows and camera filters
- `tools/analyze-gcode.ps1`, `tools/find-makeit-cache.ps1`, `tools/derelativize-gcode.ps1`,
  `tools/dump-prefs-devices.ps1`, `tools/stage5-jobfile-grab.ps1`, `tools/test-machine.ps1`
- ~30 hardware captures under `captures/`
- `outreach/` — vendor and community reports, with plain-text variants for email
- `RESUME-HERE.md`, GitHub issue templates, and a CI workflow that regenerates and validates
  every profile

### Fixed

- Profiles now carry `M18S0` / `M18S1` in the User Start Script, air assist off, `mirrorY: true`,
  and a top-left origin.
- CI compared generated profiles **byte for byte**, so PowerShell 5.1 output could never match
  CI's `pwsh` 7 indentation. It now compares parsed JSON content and no longer fails every push.

### Known limitations

- Large fills are not yet trustworthy — pending the vendors' upload path.
- Rotary, slide extension, conveyor, K9 crystal and camera alignment remain untouched.
- `Enable Q-Pulse Options` is untested and is now the highest-value open item.

## [0.1.0] — 2026-08-24 — Pre-hardware baseline

First public shape of the project. **Nothing here has been verified on a physical Lumos Ultra.**

### Findings

- **The Lumos family is a GRBL / G-code serial device to LightBurn, not a galvo controller.**
  Established by reading WeCreat's own `WeCreat-Lumos-v1.5.lbdev`: `"Name": "GRBL"`,
  `"Type": "Serial"`, `BaudRate 1000000`, 116 × 116 mm, `MirrorY: true`, `S_Scale 1000`.
  Corroborated by LightBurn staff and by depth-map failures reported on the Lumos.
- **Consequence:** LightBurn's Q-Pulse Width, Frequency, lens correction, galvo rotary, Split
  Marking and 3D depth-map features are galvo-class and therefore unavailable. This is
  structural, not a missing config file.
- **The controller is a Linux SBC with a separate MCU.** WeCreat's own bundled RNDIS driver binds
  `USB\VID_0525&PID_a4a2` and `USB\VID_1d6b&PID_0104&MI_00` — Linux USB gadget IDs, composite
  device.
- **The Lumos Ultra has nine work modes**, enumerated from the shipping MakeIt! 3.0.6 bundle:
  plane, cylinder, emboss, crystal, crystal3D, autoslider, autosliderCylinder, conveyorbelt,
  conveyorBeltSlide.
- **MakeIt's application logic is encrypted** (`f.enc`, ~41 MB) with the main/preload bundles
  compiled to V8 bytecode. Static extraction of the Ultra's M-code table is **not possible** —
  live capture or the firmware tarball are the routes. Documented so nobody repeats the attempt.
- **MakeIt updates from a GitHub repository**, `yuerugoutql/makeit-builder` (per
  `app-update.yml`). Visibility unconfirmed — a lead.
- The installed MakeIt build (3.0.6) is **ahead of WeCreat's published changelog** (3.0.2), which
  never mentions the Lumos Ultra at all.
- Compiled the most complete public **WeCreat M-code dictionary** we know of, with per-model
  scoping and evidence grades. Corrected three claims circulating elsewhere: `M14` is a fan, not
  a bulk-mode switch; there is no `M13`; AlgoLaser's `M16`/`M17` semantics do not transfer.

### Added

- `README.md`, `SAFETY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, MIT `LICENSE`
- `docs/01` … `docs/12` — architecture, feature inventory, bring-up plan, M-code dictionary,
  connectivity, modes and lenses, accessories, cameras, the MOPA/K9 limits, `.lbdev` format,
  MakeIt internals, checklists
- `docs/evidence/sources.md` — every source, plus an explicit list of gaps in our own research
- Six draft profiles in `profiles/draft/`, generated from `tools/profile-spec.json`
- `tools/` — workstation probe, vendor profile fetcher, `.lbdev` summarizer, profile generator,
  profile validator, `.asar` reader, binary string scanner
- `captures/templates/` — six capture templates, four of which need no beam
- GitHub issue forms, PR template, and a CI workflow that regenerates profiles, enforces the
  safety and hygiene rules, and refuses vendor material

### Safety posture

All shipped profiles have **empty start/end G-code, no macros, and Z disabled**, and carry a
start-of-job checklist. `tools/validate-lbdev.ps1` enforces this and runs in CI.

### Known unknowns

Eight open questions are tracked in
[`docs/02-feature-inventory.md`](docs/02-feature-inventory.md#open-questions). The first —
*does the Ultra present as a GRBL serial device?* — is a two-minute test that everything else
depends on.
