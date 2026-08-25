# ⚠️ Which device class have we actually been testing?

**Date:** 2026-08-25 · **Status:** 🔴 OPEN — needs a fresh `prefs.ini` to settle
**Source:** `captures/lightburn-prefs-benchy-20260824-110824.ini` (captured **2026-08-24**, so it
predates today's origin change)

## What the prefs file contains

| # | DisplayName | class | GCodeFlavor | size | MirrorX/Y | HomeOnStartup | CutOrigin |
|---|---|---|---|---|---|---|---|
| 0 | Genmitsu 10W … | GRBL | — | 300×300 | F / F | True | 2 |
| 1 | WeCreat Lumos (3) (1) (1) | GRBL | — | 116×116 | F / **True** | False | 2 |
| 2 | **WeCreat Lumos Ultra - MOPA 100W Red 210** | **GRBL** | — | 210×210 | F / **True** | False | 2 |
| 3 | WeCreat Lumos Ultra - MOPA Red 210 | **Custom GCode** | **wecreat** | 210×210 | F / F | **True** | — |

## The problem

LightBurn's title bar throughout today's Stage 4 work read:

> `<untitled> * - WeCreat Lumos Ultra - MOPA 100W Red 210 - LightBurn Core 2.1.04`

That is **device [2] — a GRBL-class device with no `GCodeFlavor`.** Not device [3], which is the
Custom GCode / `wecreat` profile this project has been recommending.

If that mapping still holds today, then **every Stage 4 result — the origin corner, the `err:20`
diagnosis, the framing behaviour, the distortion measurement — was obtained on a GRBL profile.**

## What this puts in doubt

| Claim | Status now |
|---|---|
| "`GCodeFlavor: wecreat` is doing real work — LightBurn emits `Exit_Preview_Mode` / `M41Y1`" | **Probably wrong.** Those appeared on a device with no GCodeFlavor set. Far more likely LightBurn recognises the `[WeCreat Lumos :ver 000240]` banner and enables WeCreat behaviour regardless of device class. **Retract pending confirmation.** |
| "Custom GCode is the correct device class" | **Unproven.** A GRBL-class profile demonstrably connects, frames, and drives preview mode |
| Origin / mirroring result | **Still valid** — it was measured on whatever device was actually driving the machine, and the machine agreed with the screen. But it must be applied to *that* device |
| Distortion result | **Still valid** — a property of the machine, not of the profile |

## Suspicious details in device [3]

- `HomeOnStartup: True` — `tools/validate-lbdev.ps1` explicitly **rejects** this. Either the
  generator emitted it, or LightBurn re-defaulted it on import. Needs checking either way.
- `CutOrigin` absent, consistent with [docs/10](../docs/10-lbdev-format.md): the Custom GCode class
  has no `CutOrigin` key. Device [2], being GRBL, has `CutOrigin: 2`.

## Note on `MirrorY`

Device [2] already carried `MirrorY: True` **yesterday**, before today's Origin change. Today the
Origin selector showed *bottom-left* and we changed it to *top-left*. So the mapping between the
Origin corner widget and the stored `MirrorX`/`MirrorY` pair is **not** the simple one assumed in
[the Test 2 capture](stage4-mirror-origin-benchy.md) — `CutOrigin` is likely carrying part of it.

**Do not update `tools/profile-spec.json` from inference.** Read the fresh file.

## To settle this — one question and one file

1. **In LightBurn, which device is selected in the dropdown right now?** If it reads
   *"MOPA 100W Red 210"*, we have been on GRBL all day.
2. **Fresh `prefs.ini`** — close LightBurn, run `\\cortex\D\lumos.cmd` on benchy, press `p`.
   Then: `tools\dump-prefs-devices.ps1 -Path captures\lightburn-prefs-benchy-<new>.ini`

## Why this might be good news

If a **GRBL**-class profile connects, is detected as a WeCreat device, drives preview mode, frames
accurately and streams jobs, that is a *better* answer than Custom GCode: GRBL is the
better-supported class in LightBurn, with more of the UI live. The project may have been steering
people toward the harder path.

**Do not rewrite the recommendation yet.** Get the file, compare the two device classes on the same
machine, and let the evidence decide — the same way every other question here has been settled.

---

## Corroborating evidence: LightBurn ships a WeCreat camera preset

LightBurn 2.1.04's **Camera Presets** dialog lists vendors, and WeCreat is one of them:

| Vendor | Preset | Description, verbatim |
|---|---|---|
| Creality | Falcon A1 Pro | Network connection to Creality Falcon A1 Pro camera over USB |
| Thunder Laser | Vision Overview | Network connection to Thunder Laser Vision System (Port 8091) |
| Thunder Laser | Vision Head-Mounted | Network connection to Thunder Laser Vision System (Port 8089) |
| **WeCreat** | **WeCreat** | **Network connection to WeCreat camera over USB** |
| xTool | P2 | Network connection to xTool P2 camera over USB |

Two things follow.

### 1. WeCreat support in LightBurn is built in, not something we configured

There is a first-class WeCreat entry sitting beside xTool and Thunder Laser. That makes it far more
likely that **"Found WeCreat Device", `Exit_Preview_Mode` and `M41Y1` come from LightBurn's own
WeCreat handling, triggered by the `[WeCreat Lumos :ver 000240]` banner** — not from our
`GCodeFlavor: "wecreat"` string. It is consistent with those behaviours appearing on a GRBL-class
device with no flavor set.

**The retraction above stands, and this strengthens it.**

### 2. "Network connection … over USB" independently confirms our architecture

That phrase is exactly the architecture this project reverse-engineered from scratch
([docs/01](../docs/01-architecture.md), [docs/05](../docs/05-connectivity.md)): one USB cable →
internal hub → a **Linux RNDIS gadget** presenting a private network, with the camera served over
HTTP on that network. Not a UVC webcam. Not a serial camera.

We derived that from USB enumeration and HTTP probing. **LightBurn's own UI wording says the same
thing** — and it is the same pattern Creality and xTool use, which is why all three read
"Network connection … over USB".

Independent confirmation of a finding this project made the hard way, from the vendor's tooling
rather than from our probes. Grade for the RNDIS-over-USB camera path: **CONFIRMED-vendor.**

---

## ✅ CONFIRMED by the operator, 2026-08-25

**The selected device throughout Stage 4 was "WeCreat Lumos Ultra - MOPA 100W Red 210" — the
GRBL-class profile.** Not the Custom GCode / `wecreat` one.

### What a GRBL-class profile demonstrably does on a Lumos Ultra

| Capability | Result |
|---|---|
| Connects at 1,000,000 baud over the CH340 | ✅ |
| Recognised as **"Found WeCreat Device"** | ✅ |
| Drives preview mode / red pointer (`Exit_Preview_Mode`, `M41Y1`) | ✅ |
| Frames accurately, screen matches machine | ✅ |
| Reaches all four corners of a 200 mm square | ✅ |
| Live `MPos` tracking with the `−105` field-centre offset | ✅ |
| Exposes `CutOrigin` — a real origin-corner control | ✅ |
| Exposes `MirrorX` / `MirrorY` | ✅ |

**Everything this project needs, on the better-supported device class.**

## ⚠️ This also confounds the `err:20` diagnosis

The two runs being compared were **not** on the same device:

| Run | Device class | `M8`/`M9` present | `err:20` |
|---|---|---|---|
| Saved marking job (`captures/lightburn-job.gc`, 2026-08-24) | **Custom GCode** | yes | **2** |
| Framing runs (2026-08-25) | **GRBL** | no | **0** |

Two variables changed at once. The `M8`/`M9` reading remains plausible — it is still the only pair
of commands that fits a count of exactly two — but **it is no longer a clean differential** and
must not be written up as one.

**The clean test:** on **one** device, run the same job twice, air assist **on** then **off**.
One variable. That is the house method and it has not been applied here yet.

## The decision this forces

The repository currently recommends `Custom GCode` + `GCodeFlavor: "wecreat"`
([docs/10](../docs/10-lbdev-format.md), `tools/profile-spec.json`, `tools/validate-lbdev.ps1`).
That recommendation was reasoned, but it was never tested against GRBL on hardware — and GRBL is
what actually did the work.

Reasons GRBL may be the better recommendation:

- **More of LightBurn is live.** Jogging, position readout, homing controls, origin corner
- **`CutOrigin` exists.** The Custom GCode class has no such key, which is why
  [Test 2](stage4-mirror-origin-benchy.md) had to resolve the corner through the Origin widget with
  an unclear mapping to `MirrorX`/`MirrorY`
- **It is the class WeCreat's own vendor profile uses** for the Lumos (device [1], `Name: GRBL`)
- **It works.** Demonstrated, today, on this machine

Reason to be careful: `GCodeFlavor: "wecreat"` may still change job output in ways framing did not
exercise. Framing emits no `M4`, `M8`, `M9`, `S` or power terms.

## The experiment that decides it — beam-free, ~10 minutes

Same LightBurn file, same square, **Save GCode** from each device in turn, then diff.

1. Draw a 20 mm square, air assist **OFF**. Save as `captures/gcode-grbl-noair.gc`
2. Same file, air assist **ON**. Save as `captures/gcode-grbl-air.gc`
3. Switch device to **"MOPA Red 210"** (Custom GCode). Repeat both:
   `captures/gcode-customgcode-noair.gc`, `captures/gcode-customgcode-air.gc`

Four files, no beam, no machine time. They settle **both** open questions at once:

- `noair` vs `air` on the same device → **isolates `M8`/`M9`**, the clean differential we owe this
- GRBL vs Custom GCode → **shows exactly what the device class changes** in emitted output

Then one live run of the winning combination confirms `err:20` goes to zero.

---

# ❌ THIS ENTIRE CAPTURE'S CONCLUSION IS WRONG — see the correction

**2026-08-25, later the same day.** The saved G-code proves the device is **Custom GCode**, not
GRBL. Both files carry the header `;Custom GCode device profile, absolute coords`.

The DisplayName *"WeCreat Lumos Ultra - MOPA 100W Red 210"* is used by **both** a GRBL device in the
stale prefs file **and** by our own generated Custom GCode profile. The name cannot identify the
class, so the confirming question asked above was unanswerable as posed.

**Full correction, and the air-assist differential that came out of it:**
[stage4-airassist-differential.md](stage4-airassist-differential.md)

Kept unedited above as a record of the reasoning error. The method lesson is worth more than the
tidy-up: **identify a LightBurn device by the `;` header of its emitted G-code, never by its
DisplayName.**
