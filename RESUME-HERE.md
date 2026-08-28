# Resume here

**Last session: 2026-08-27.** Read this first when picking the project back up.

## The one-paragraph version

The repo is public. It marks, it places accurately, and its geometry is confirmed. The streaming
defect that dominated the last fortnight **now belongs to WeCreat and LightBurn**, who are jointly
implementing job upload instead of real-time streaming. This project's role there has changed from
diagnosing to testing. **The actual mission — a configuration covering every source, lens and
accessory — is largely untouched, and none of it waits on the upload path.**

<https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config>

## Where things stand

| | |
|---|---|
| Architecture, USB, baud, M-code dialect | ✅ confirmed on hardware |
| Field 210 × 210, origin top-left, `MPos = commanded − 105` | ✅ confirmed |
| Field distortion at 200 mm | ✅ none detectable (< 0.2 mm) |
| First marks — 15 % @ 12000 mm/min on black anodized | ✅ confirmed |
| MOPA frequency / pulse width, including **mid-job** changes | ✅ confirmed |
| Camera via LightBurn's built-in WeCreat preset | ✅ connects |
| Streaming reliability on long jobs | 🟠 **handed off — vendors own it** |
| Rotary / slide / conveyor / K9 / camera alignment | ⬜ **next** |

## Both vendors replied — 2026-08-27

Full text and analysis: [`captures/vendor-responses-2026-08-27.md`](captures/vendor-responses-2026-08-27.md)

| Who | What they said |
|---|---|
| **Allen, WeCreat support** | "Almost all of your findings are correct." Upload-to-internal-memory is being implemented with LightBurn; test builds close. Corrected their own published spec — UV spot is **6–8 μm**, not 0.0019 mm (that was motion accuracy). MakeIt's 256 layers is 8-bit software, not a controller limit. **Named himself the primary point of contact** and asked to keep discussion in one email thread |
| **Aaron, LightBurn support** | LightBurn reads buffer size from `OPT:` in `$I`; absent that it defaults to 128. The manual override is buggy and **a fix is written** |
| **Jon C, LightBurn dev team** | At a buffer of **≥127 the Ultra drops moves**. He is in direct talks with WeCreat. Separately: relative fills ran **without drift** on *their* Ultra, and he suspects **unreleased firmware** — and would not be surprised if LightBurn had been sent an in-flight build |
| **Mike Hembrey, forum** | Engaged, gracious, no Ultra of his own |

**Answered 2026-08-28, and it went the other way.** LightBurn's Ultra reads **`ver 000236`** —
*older* than this machine's `000240`. Jon's reading: *"looks like they have a regression."*

That is now **the biggest lead in the project**. Every other explanation on file — fabricated
status report, buffer mismatch, `G91` amplification — is a property of the design, and a design
does not differ between two units of one model. A version number does.
[Capture](captures/firmware-000236-vs-000240-regression.md). Not proven: the comparison is not
fully matched, and no owner can downgrade to test it. WeCreat can settle it from the changelog.

## What was learned on 2026-08-27

[`captures/makeit-cache-and-absolute-gcode.md`](captures/makeit-cache-and-absolute-gcode.md)

**MakeIt stages the whole job on the PC** at `%APPDATA%\Wecreat MakeIt!\gcode\gcode.gc`. No packet
capture needed to read WeCreat's own generator output. Tools:
`tools/find-makeit-cache.ps1`, `tools/analyze-gcode.ps1`.

1. **222 MB, 11,276,586 lines, one job.** At 1,000,000 baud that is ~39 minutes of pure payload
   before any acknowledgement. Streaming a job like that is not slow, it is impossible — which is
   the real argument for upload, and it is measured rather than asserted
2. **Zero `G91` in 11.3 million moves.** WeCreat never uses relative mode. *Caveat kept in the
   open: they upload, so they had no bandwidth to save — the choice is probably incidental*
3. **282 `M38` + 282 `M39` in one job.** The controller accepts frequency and pulse-width changes
   **mid-job**, and the vendor's software relies on it. This is the strongest lead for
   `Enable Q-Pulse Options` and means [docs/09](docs/09-k9-and-mopa-limits.md) needs revisiting

## Outreach state

| Where | Status |
|---|---|
| WeCreat support | **Follow-up SENT 2026-08-27 06:37**, five questions, unanswered as of end of day — recorded verbatim in `outreach/plaintext/wecreat-followup-2026-08-27-SENT.txt`. A second message on controller configuration and network exposure is drafted and **on hold** until that exchange closes |
| LightBurn forum, WeCreat category | Live thread, three staff/dev replies. Posted a correction that landed well. **Reply 3 drafted and unsent**: `outreach/lightburn-forum-reply-3-2026-08-27.md` |
| WeCreat owners' FB group | Original posted 2026-08-26. **Follow-up posted 2026-08-27** (vendor credit, the 222 MB / 39-minute finding, mid-job MOPA control). **Delta comment posted 2026-08-28** — eyewear correction plus the `000236` / `000240` regression, and the community bisect ask. **Watch this thread**: version strings and fill results from other owners are the next real evidence |
| LightBurn users' FB group | Draft exists; posting status unconfirmed |
| Chris Zambesi | First community contributor. **Ran the fill test 2026-08-27: a 90 × 90 mm fill completed cleanly on his Flex.** But he used the *diode*, and slow jobs never starve the buffer — so it is not yet a matched comparison. Asked him for speed and fill type; awaiting reply. [Capture](captures/community-01-lumos-flex-chris-zambesi.md) |

## Next moves, in order

### Owed to ourselves
1. **A clean drift measurement.** The published 2.30 mm came from a run contaminated by
   Pause/Resume. Use Offset Fill or a small dense fill that can actually *complete*, never touch
   Pause/Resume, compare final `MPos` to declared bounds. Confirms the mechanism or retires a claim
   — and retiring it would be the more valuable outcome
2. **Blank the `Air On` / `Air Off` templates.** `M8` is rejected and still in every job

### The actual mission
3. **`Enable Q-Pulse Options`** — firmware side now confirmed, see finding 3 above
4. **Green lens / K9 2D surface marking** — plausible today, completely untested
5. **Camera alignment** — self-contained, needs no beam
6. **Rotary, slide, conveyor** — investigation before configuration

### Tracked, not chased
7. Firmware version from Jon · the buffer-override fix · the upload test builds

## Practical notes for whoever picks this up

- **Identify a LightBurn device by the `;` header of its emitted G-code, never by DisplayName.**
  Two device classes can share a name. That mistake cost an afternoon and is written up in
  `captures/stage4-which-device-are-we-testing.md` rather than hidden
- Profiles are generated: edit `tools/profile-spec.json`, run `tools/build-profiles.ps1`,
  `tools/validate-lbdev.ps1` must pass
- **CI compares profile JSON *content*, not bytes** — PowerShell 5.1 and CI's `pwsh` 7 indent
  differently, which failed every build for a week. See `captures/ci-validate-failure-json-indent.md`
- `M18S0` lives in the profile's **User Start Script**, not `StartGCode` (which this device class
  ignores). `M15S0` in User End Script stops the fan
- Air assist **off** — `M8` is rejected, and off still emits `M9` twice
- **Frame can fire the beam.** Not a gantry laser; the habit does not transfer
- **Do not build an upload bridge.** The endpoint is confirmed and the format is plain G-code, but
  the vendors are shipping the official path and LightBurn has no plugin hook to route jobs through
  a third-party one. Characterise it for their benefit; do not duplicate it
- `tools/derelativize-gcode.ps1` converts a saved `.gc` from relative to absolute for use with
  **Run GCode**. Does not fix stalls; makes them survivable
- Machines: **cortex** = dev workstation (repo lives here, share is `\\cortex\D`),
  **benchy** = basement PC with the laser on USB. Launcher: `\\cortex\D\lumos.cmd`
- PowerShell scripts need `powershell -ExecutionPolicy Bypass -File ...` on benchy
- Raw capture video is gitignored (`docs/images/*.mp4`) and stays local — it was stripped from
  history once already
