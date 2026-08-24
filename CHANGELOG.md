# Changelog

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
