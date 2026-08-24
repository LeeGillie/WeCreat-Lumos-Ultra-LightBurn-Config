# profiles/

> ## ⚠️ These profiles are the wrong device class — regeneration pending
>
> On first connection (2026-08-24) LightBurn 2.1.04 said:
>
> > *"Your laser has been detected as a WeCreat device but you are not using a custom gcode
> > device with the WeCreat device flavor. The device may not work correctly as a result."*
>
> **LightBurn has a native WeCreat device flavor.** These profiles declare `"Name": "GRBL"`,
> modelled on WeCreat's own `WeCreat-Lumos-v1.5.lbdev` — which dates from August 2025 and
> predates that flavor. The vendor's profile is outdated too, and produces the same warning.
>
> They **do connect** and the handshake works. But the correct configuration is a **Custom GCode**
> device with flavor **WeCreat**, plus *Supports G53 Command* and *Fetch configuration on connect*
> both disabled. See [the capture](../captures/stage3-lightburn-connect-benchy.md).

## `draft/` — generated, unverified

Six LightBurn device profiles for the Lumos Ultra. **None has been tested on a physical machine.**

| File | Source | Lens | Workspace |
|---|---|---|---|
| `WeCreat-Lumos-Ultra-UV-Purple-210.lbdev` | 6 W UV | Purple | 210 × 210 mm |
| `WeCreat-Lumos-Ultra-UV-Green-K9-70.lbdev` | 6 W UV | Green | 70 × 70 mm |
| `WeCreat-Lumos-Ultra-MOPA60-Red-210.lbdev` | 60 W MOPA | Red | 210 × 210 mm |
| `WeCreat-Lumos-Ultra-MOPA100-Red-210.lbdev` | 100 W MOPA | Red | 210 × 210 mm |
| `WeCreat-Lumos-Ultra-Slide-520x183.lbdev` | any | any | 520 × 183 mm — **speculative** |
| `WeCreat-Lumos-Ultra-Conveyor-206.lbdev` | any | any | 206 × 206 mm — **speculative** |

## What is deliberately missing

Every profile ships with:

- **empty `StartGCode` and `EndGCode`**
- **no macros**
- **`EnableZ: false`**

That is not an oversight. WeCreat renumbers M-codes between machine models, and **no Lumos Ultra
M-code has been verified by anyone**. Candidate start blocks and macros are documented in
[../docs/04-mcode-dictionary.md](../docs/04-mcode-dictionary.md) and stay there until hardware
confirms them. See [../SAFETY.md](../SAFETY.md).

Each profile does carry a **start-of-job checklist** — LightBurn's only substitute for the
machine's field-lens auto-detection, which LightBurn cannot use. Please don't strip them.

## Installing one

LightBurn → Laser window → **Devices** → **Import** → pick the `.lbdev`.

Then work through [../docs/03-bringup-plan.md](../docs/03-bringup-plan.md) from Stage 3. Do not
run a job before Stage 4.

## Regenerating

Profiles are **generated**, not hand-written. Edit the spec, not the output:

```powershell
# edit tools\profile-spec.json, then
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-profiles.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate-lbdev.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\summarize-lbdev.ps1
```

`validate-lbdev.ps1` enforces the hygiene and safety rules above and runs in CI. A PR that ships
a profile with non-empty start G-code will fail the build.

## `bundle/` — not yet

Once profiles are confirmed on hardware, this will hold a single
`WeCreat-Lumos-Ultra.lbzip` User Bundle carrying all profiles plus per-source material libraries,
so users import once instead of six times. LightBurn: `File → Bundles → Import Bundle`, or drag
the `.lbzip` into the window.
