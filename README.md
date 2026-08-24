# WeCreat Lumos Ultra — LightBurn Configuration Project

![LightBurn Configuration for the WeCreat Lumos Ultra](docs/images/LightburnConfigProject.png)

<sub>Banner artwork is aspirational — it shows where this project is going, not where it is.
For actual, current status of every feature see the
[feature inventory](docs/02-feature-inventory.md). Lens part numbers shown are decorative.</sub>

An open, evidence-graded effort to build a working **LightBurn** device configuration for the
**WeCreat Lumos Ultra** (6 W UV + optional 60 W / 100 W JPT MOPA fiber), covering every field
lens, work mode and accessory.

**WeCreat does not publish a LightBurn profile for the Lumos Ultra.** They publish one for the
Vision, Vision Pro, Vista and Lumos — but not the Ultra — while simultaneously listing
"Lightburn" as supported software on the Ultra product page. This repository exists to close
that gap in the open, with contributions from anyone who owns the machine.

> **Status: pre-hardware.** Nothing in `profiles/draft/` has been confirmed against a physical
> Lumos Ultra yet. Every claim in this repository carries an evidence grade. Read
> [SAFETY.md](SAFETY.md) before you connect anything.

---

## What we already know (and how well)

| Finding | Grade |
|---|---|
| WeCreat's LightBurn profiles are **GRBL / G-code serial devices**, not galvo controllers | **CONFIRMED** — read out of WeCreat's own `WeCreat-Lumos-v1.5.lbdev`: `"Name": "GRBL"`, `"Type": "Serial"`, `BaudRate 1000000` |
| The Lumos-family controller is a **Linux SBC front-end with a separate MCU** | **CONFIRMED** — WeCreat's bundled RNDIS driver binds `USB\VID_0525&PID_a4a2` and `USB\VID_1d6b&PID_0104&MI_00` (Linux USB gadget IDs); the reverse-engineered REST endpoint is literally `/test/cmd/mcu` |
| WeCreat uses a **private M-code dialect** that is renumbered per machine model | **CONFIRMED** — see [docs/04-mcode-dictionary.md](docs/04-mcode-dictionary.md) |
| MakeIt! 3.0.6 ships **nine distinct Lumos Ultra work modes** | **CONFIRMED** — enumerated from the shipping application bundle, see [docs/06-modes-and-lenses.md](docs/06-modes-and-lenses.md) |
| The Ultra specifically uses the same GRBL-over-serial path | **STRONG INFERENCE, UNVERIFIED** — no one has publicly connected an Ultra to LightBurn. This is [open question #1](docs/02-feature-inventory.md#open-questions) |
| LightBurn's galvo features (Q-Pulse Width, lens bulge/skew correction, galvo rotary, Split Marking, 3D depth-map) are **unavailable** on a GRBL-typed device | **CONFIRMED for the Lumos**, inferred for the Ultra |

The single most consequential consequence: **if the Ultra is a GRBL device to LightBurn, then
LightBurn cannot drive MOPA pulse width, cannot do 16-bit depth-map relief, and cannot do K9
internal 3D engraving** — not because of a missing config file, but because those features live
in LightBurn's galvo device class, which this machine does not use. Anything we recover there
has to come through custom G-code, not through LightBurn's UI.

## What this repository contains

```
docs/         The research. Architecture, feature inventory, M-code dictionary,
              connectivity, modes and lenses, accessories, cameras, K9 crystal,
              .lbdev file format, MakeIt internals, and a full source list.
profiles/     Draft LightBurn device profiles (.lbdev), one per lens/source/mode.
tools/        Scripts to probe your workstation, fetch vendor reference profiles,
              summarize any .lbdev, generate profiles, and inspect MakeIt.
captures/     Where contributors drop their hardware findings. Templates included.
reference/    Local-only working area. Gitignored. Vendor files are NOT redistributed.
```

## Quick start (no laser required)

```powershell
# 1. See what your PC has
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1

# 2. Pull WeCreat's official profiles for the other machines, as reference
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\fetch-vendor-lbdev.ps1

# 3. Read any .lbdev in human form
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\summarize-lbdev.ps1 .\reference\vendor-lbdev

# 4. Generate the draft Ultra profiles
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-profiles.ps1
```

## Quick start (with a Lumos Ultra)

**Do not skip [SAFETY.md](SAFETY.md).** If the laser lives on a different machine from the one
you author on, [docs/13-test-machine-setup.md](docs/13-test-machine-setup.md) covers getting the
repo onto it and checking it is ready. Then work through
[docs/03-bringup-plan.md](docs/03-bringup-plan.md) in order. Stage 0 and Stage 1 involve no beam
at all and are the most valuable thing any owner can contribute right now.

The three highest-value contributions today, in order:

1. **USB enumeration.** Plug in the Ultra, run `tools/probe-workstation.ps1`, and open an issue
   with the output. This settles the architecture question outright.
2. **The serial banner and `$$` dump.** Connect at 1,000,000 baud and capture what the machine
   says on connect. Expect something shaped like `[WeCreat Lumos Ultra :ver ######]`.
3. **A MakeIt job capture.** Run the same tiny job twice, changing exactly one thing (UV vs
   MOPA; two pulse widths; two focus heights), and capture the G-code. This is how the Ultra's
   M-code table gets written.

Templates for all three live in [`captures/templates/`](captures/templates/).

## How to help

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version: we grade every claim, we never guess in
the documentation, and we never ask anyone to send an unknown M-code to a 100 W fiber laser to
find out what it does. Issues are structured by kind — feature status, M-code discovery, profile
bug, calibration data.

You do not need to own an Ultra to help. Reviewing the docs, improving the tooling, testing the
profile generator, and chasing down sources are all useful.

## Scope and honesty

This project can produce a **LightBurn configuration**. It cannot invent controller capabilities
that WeCreat has not exposed. Where a feature turns out to be MakeIt-only, we will say so plainly
and document *why*, rather than shipping a profile that pretends otherwise.

## Legal

Repository content is MIT licensed — see [LICENSE](LICENSE).

WeCreat's own `.lbdev` files, firmware, and application code are **not redistributed here**.
`tools/fetch-vendor-lbdev.ps1` downloads them from WeCreat's public CDN to your own machine for
comparison, and `reference/` is gitignored. Where this project inspects a locally installed copy
of MakeIt!, it does so to determine the interface the operator's own hardware expects — an
interoperability purpose — and publishes only the resulting factual findings, never WeCreat's code.

This project is not affiliated with, endorsed by, or supported by WeCreat or LightBurn Software.
