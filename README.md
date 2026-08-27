# WeCreat Lumos Ultra — LightBurn Configuration Project

![LightBurn Configuration for the WeCreat Lumos Ultra](docs/images/LightburnConfigProject.png)

<sub>Banner artwork is aspirational — it shows where this project is going, not where it is.
For actual, current status of every feature see the
[feature inventory](docs/02-feature-inventory.md). Any lens part numbers in the artwork are
decorative — the real ones, read off the glass, are in
[docs/06](docs/06-modes-and-lenses.md).</sub>

An open, evidence-graded effort to build a working **LightBurn** device configuration for the
**WeCreat Lumos Ultra** (6 W UV + optional 60 W / 100 W JPT MOPA fiber), covering every field
lens, work mode and accessory.

**WeCreat does not publish a LightBurn profile for the Lumos Ultra.** They publish one for the
Vision, Vision Pro, Vista and Lumos — but not the Ultra — while simultaneously listing
"Lightburn" as supported software on the Ultra product page. This repository exists to close
that gap in the open, with contributions from anyone who owns the machine.

> ## Status — it marks, it places accurately, and long jobs are now somebody else's bug
>
> **2026-08-25: the first real mark.** A 20 mm square, from LightBurn, at 15 % power on black
> anodized aluminium — correct size, correct position, cleanly defined.
>
> **2026-08-27: both vendors engaged, and the streaming defect has an owner.** WeCreat and
> LightBurn are jointly implementing job upload to the machine's internal memory instead of
> real-time streaming, with test builds said to be close. This project's job on that front has
> changed from *diagnosing* to *testing and documenting*.
>
> | | |
> |---|---|
> | Architecture, USB identity, baud, M-code dialect | ✅ confirmed on hardware |
> | Field size 210 × 210, origin corner, coordinate mapping | ✅ confirmed on hardware |
> | Field distortion at 200 mm | ✅ none detectable |
> | Marking, power scaling, placement | ✅ confirmed on hardware |
> | Camera | ✅ connects via LightBurn's built-in WeCreat preset |
> | MOPA frequency and pulse width, including **mid-job** changes | ✅ confirmed on hardware |
> | Streaming reliability on long jobs | 🟠 **understood; fix in flight at both vendors** |
> | Rotary, slide, conveyor, K9, camera alignment | ⬜ **next — and none of it waits on the above** |
>
> Every claim below carries an evidence grade. Read [SAFETY.md](SAFETY.md) before you connect
> anything — including the part about **Frame firing the beam**.
>
> ### 🟠 Long jobs: what happens, and why it is not this project's problem to solve
>
> Fills stall part-way and drift. Both vendors responded within a day of this repo going public,
> and the cause is confirmed from both ends
> ([full responses](captures/vendor-responses-2026-08-27.md)):
>
> ```
> WeCreat firmware returns no OPT: in its $I response
>         ↓  LightBurn falls back to a 128-byte buffer
>         ↓  at ≥127 bytes the controller DROPS MOVES     ← confirmed by a LightBurn dev
>         ↓  a dropped move inside a G91 relative block
>         ↓  every later position inherits the error
> ```
>
> A **LightBurn developer** reports the machine's serial receive buffer and its motion chip's
> buffer are different sizes, and that at 127 bytes or more it simply drops moves. The buffer
> value cannot currently be lowered because of a separate LightBurn bug — **which already has a
> fix written**.
>
> **But the deeper point is arithmetic, and it is measured.** A single real MakeIt job — read from
> WeCreat's own staged output — is **222 MB and 11,276,586 lines**. At 1,000,000 baud that is about
> **39 minutes of pure payload** before a single acknowledgement round trip.
> ([measurements](captures/makeit-cache-and-absolute-gcode.md))
>
> Streaming a job of that size is not slow. It is not possible. No buffer size changes that, which
> is why upload-to-device is the correct architecture rather than merely a convenient one — and it
> is exactly what MakeIt has always done.
>
> **Today: honest for vector work, not yet trustworthy for large fills.** Analysis:
> [streaming stalls](captures/stage5-streaming-stalls.md) ·
> [G91 measurements](captures/stage5-G91-relative-mode-CONFIRMED.md) ·
> [MakeIt's own G-code](captures/makeit-cache-and-absolute-gcode.md)
>
> One caveat kept in plain sight: the "2.30 mm outside declared bounds" figure this project
> published came from a run in which Pause/Resume had been used repeatedly to unstick a stall, so
> it cannot separate dropped moves from the recovery attempt. A clean measurement is owed.
> ([why](captures/stage5-drift-measured-and-pause-harm.md))

> ### 🙏 Contributors
>
> **[Chris Zambesi](captures/community-01-lumos-flex-chris-zambesi.md)** — first community report,
> offered within hours of this repo going public. Connected a **Lumos Flex** and reported
> LightBurn's warning that the machine was detected as a WeCreat device but the profile was not
> using the WeCreat G-code flavor.
>
> That single observation confirmed three things this project had only *inferred*, on a machine we
> do not own: that LightBurn detects WeCreat controllers from the banner rather than the profile,
> that `Custom GCode` + `wecreat` is the class LightBurn itself wants, and that WeCreat's official
> configs predate that flavor. It also established that the **Flex is 116 × 116 mm**, which means
> the workspace trap below is **Ultra-specific**.
>
> This is exactly what the repo was published for.

> ### ⚠️ If you own a Lumos Ultra, do not just import WeCreat's Lumos profile
>
> The Ultra identifies itself over USB as **`[WeCreat Lumos :ver 000240]`** — it does **not** say
> "Ultra". Nothing in the handshake distinguishes the two machines, so WeCreat's official
> `WeCreat-Lumos-v1.5.lbdev` **will connect to an Ultra without complaint**.
>
> That profile declares a **116 × 116 mm** workspace. The Ultra's field is **210 × 210 mm**.
> Jobs would be silently mis-scaled and mis-placed, with no error and no warning.
> ([evidence](captures/stage1-serial-benchy.md))

---

## What we already know (and how well)

| Finding | Grade |
|---|---|
| WeCreat's LightBurn profiles are **GRBL / G-code serial devices**, not galvo controllers | **CONFIRMED** — read out of WeCreat's own `WeCreat-Lumos-v1.5.lbdev`: `"Name": "GRBL"`, `"Type": "Serial"`, `BaudRate 1000000` |
| The Lumos-family controller is a **Linux SBC front-end with a separate MCU** | **CONFIRMED** — WeCreat's bundled RNDIS driver binds `USB\VID_0525&PID_a4a2` and `USB\VID_1d6b&PID_0104&MI_00` (Linux USB gadget IDs); the reverse-engineered REST endpoint is literally `/test/cmd/mcu` |
| WeCreat uses a **private M-code dialect** that is renumbered per machine model | **CONFIRMED** — see [docs/04-mcode-dictionary.md](docs/04-mcode-dictionary.md) |
| MakeIt! 3.0.6 ships **nine distinct Lumos Ultra work modes** | **CONFIRMED** — enumerated from the shipping application bundle, see [docs/06-modes-and-lenses.md](docs/06-modes-and-lenses.md) |
| **The Ultra specifically is a GRBL-over-serial device** | **CONFIRMED-hardware, 2026-08-24** — a physical Lumos Ultra enumerates as a CH340 serial bridge (`VID_1A86&PID_7523`) plus a Linux RNDIS gadget (`VID_0525&PID_A4A2`), with **no galvo controller present**. [Capture](captures/) · [analysis](docs/01-architecture.md#4-confirmed-on-a-physical-lumos-ultra--2026-08-24) |
| The controller sits on a private USB network at `192.168.42.0/24` | **CONFIRMED-hardware** — the RNDIS adapter comes up at `192.168.42.100`, putting the controller at (almost certainly) `192.168.42.1` |
| LightBurn's galvo features (lens bulge/skew correction, galvo rotary, Split Marking, 3D depth-map) are **unavailable** on a GRBL-typed device | **CONFIRMED for the Lumos**, and the Ultra inherits the same limits. **Q-Pulse is now in doubt** — an `Enable Q-Pulse Options` toggle exists on the Custom GCode device; untested ([docs/09](docs/09-k9-and-mopa-limits.md)) |
| **All three lens part numbers, read off the glass** | **CONFIRMED-hardware** — UV `YL-355-200-F290-FS10-D`, crystal `JG-SL-355-100-70G-10`, MOPA `SL-1064-200-F290-D10-C`. **1064 nm is confirmed**, which WeCreat has never published. UV and MOPA share an identical prescription; both are rated 200 mm while the machine is driven to 210 ([docs/06](docs/06-modes-and-lenses.md)) |
| **`M18` source select is required to mark at all** | **CONFIRMED-hardware** — without it the machine streams a job and marks nothing at any power. It belongs in the profile's **User Start Script**; `StartGCode` is ignored by this device class |
| LightBurn ships **built-in WeCreat support** | **CONFIRMED-vendor** — a WeCreat camera preset whose URL, `http://192.168.42.1:8080/camera/take_photo`, is character-for-character the endpoint this project found by probing, plus a `WeCreat` GCode flavor and WeCreat-specific preview-mode commands |

LightBurn's galvo-class **UI fields** are therefore unavailable. But the underlying capability
turned out not to be:

> ### ✅ MOPA pulse width and frequency ARE controllable — including mid-job
>
> Two real MOPA jobs differing only in pulse width produced G-code differing by **exactly one
> line** — `M39P200` → `M39P500`.
>
> ```gcode
> M38F<kHz>    ; MOPA frequency        CONFIRMED-vendor
> M39P<ns>     ; MOPA pulse width      CONFIRMED-vendor
> M18S0        ; MOPA source select    CONFIRMED-vendor
> ```
>
> **And they can change during a job.** WeCreat's own staged output for a single deep-emboss job
> contains **282 `M38` and 282 `M39` statements** — the vendor's software re-tunes frequency and
> pulse width continuously as it works down through the layers. Per-layer MOPA control is not
> merely permitted by this firmware; it is routine.
> ([measurements](captures/makeit-cache-and-absolute-gcode.md))
>
> LightBurn's GRBL class supports **per-layer custom G-code** — the exact granularity a MOPA
> material library needs. You lose the convenient spin-boxes; you keep the control.
> ([evidence](captures/stage5-mopa-pulsewidth-CONFIRMED.md))

Still genuinely out of reach through LightBurn: 16-bit depth-map relief and K9 internal 3D
engraving, which need the galvo device class itself. See
[docs/09-k9-and-mopa-limits.md](docs/09-k9-and-mopa-limits.md).

**Where this is going:** [ROADMAP.md](ROADMAP.md) defines v1.0 narrowly — two profiles that
connect, place accurately and mark correctly — and lists exactly what remains.

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

The four highest-value contributions today, in order:

1. **USB enumeration.** Plug in the Ultra, run `tools/probe-workstation.ps1`, and open an issue
   with the output. This settles the architecture question outright.
2. **The serial banner and `$$` dump.** Connect at 1,000,000 baud and capture what the machine
   says on connect. Expect something shaped like `[WeCreat Lumos Ultra :ver ######]`, and
   **please report the version number** — see the firmware note below.
3. **A MakeIt job capture.** Run the same tiny job twice, changing exactly one thing (UV vs
   MOPA; two pulse widths; two focus heights), and capture the G-code. This is how the Ultra's
   M-code table gets written.
4. **Your own MakeIt output, with no laser time at all.** MakeIt stages the complete generated
   job at `%APPDATA%\Wecreat MakeIt!\gcode\gcode.gc`. Point `tools/analyze-gcode.ps1` at it and
   post the summary. It is read-only, needs no machine, and tells us how WeCreat's generator
   behaves on hardware we do not own.

Templates for all three capture types live in [`captures/templates/`](captures/templates/).

> ### 📟 Firmware versions wanted
>
> This project's machine reports **`[WeCreat Lumos :ver 000240]`**. A LightBurn developer has
> reported relative-mode fills running **without drift** on their Ultra, and suspects firmware not
> yet released publicly. If that is right, some of what is documented here may already be fixed.
>
> **If you own an Ultra, the single most useful thing you can post is your version string.**

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
