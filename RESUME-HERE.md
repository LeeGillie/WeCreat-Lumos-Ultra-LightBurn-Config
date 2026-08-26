# Resume here

**Last session: 2026-08-26.** Read this first when picking the project back up.

## Where things stand

The repo is **public**: <https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config>
67 commits, clean working tree, fresh clone 7.2 MB.

**It marks. It does not yet mark reliably.** Vector work is sound; fills stall and drift.

| | |
|---|---|
| Architecture, USB, baud, M-code dialect | ✅ confirmed on hardware |
| Field 210 × 210, origin top-left, `MPos = commanded − 105` | ✅ confirmed |
| Field distortion at 200 mm | ✅ none detectable (< 0.2 mm) |
| First marks — 15 % @ 12000 mm/min on black anodized | ✅ confirmed |
| Camera via LightBurn's built-in WeCreat preset | ✅ connects |
| **Streaming reliability on long jobs** | 🔴 **the open blocker** |
| Rotary / slide / conveyor / K9 / camera alignment | ⬜ untouched |

## Waiting on replies — this is the main reason we paused

| Sent to | When | Status |
|---|---|---|
| **WeCreat support** | 2026-08-26 | ⏳ sent, awaiting reply |
| **LightBurn** (forum, WeCreat category) | drafted, `outreach/lightburn-report.md` | check whether posted |
| **WeCreat owners' FB group** | drafted, `outreach/plaintext/facebook-group-post.txt` | posted — first reply received |
| **LightBurn users' FB group** | drafted, `outreach/plaintext/lightburn-facebook-post.txt` | check whether posted |

**Give WeCreat about a week** before reading silence as an answer. Expect tier-one to suggest
reinstalling MakeIt; ask politely for escalation to engineering and point at the repo.

**First FB reply** was Chris Zambesi asking whether LightBurn is gantry-only and which machine this
is. Answered: WeCreat publishes LightBurn configs for Vision / Vision Pro / Vista / **Lumos** (the
Lumos is a galvo, so gantry is not the dividing line); **Lumos Flex and Lumos Ultra have none**.
Verified on <https://wecreat.com/pages/software> on 2026-08-26.

## The blocker, in one paragraph

The controller's GRBL status report is **partly fabricated**: `MPos` is live and correct, but the
state field is **always `Idle`** — during a job, and even immediately after a `!` feed hold — and
`FS` is always `0,0`. LightBurn paces its stream against that, so long jobs stall. Worse, LightBurn
sends fills as **`G91` relative** moves (Plain Fill: 9,634 of 9,637 moves relative, **two** absolute
re-anchors in the whole job), so one lost line shifts everything after it permanently. Measured:
a job finished **2.30 mm outside its own declared `;Bounds:`**. And Pause/Resume — the only thing
that unsticks a stall — is itself what causes the shift.

## What has been ruled out

- `TargetBufferSize` — **cannot be changed.** UI reverts 40 → 128, and an imported `.lbdev`
  carrying 40 still shows 128. Clamped, probably by the `wecreat` flavor
- `Raster Move` template — does **not** control `G91`, only line formatting
- Query-for-position off, laser-fire off, Z-axis settings, DTR, Synchronous mode — no change
- Cable and port

## Next moves, in order

1. **Wait for WeCreat.** Only they can fix the status report — it is firmware, past the MCU boundary
2. **Baud rate 1,000,000 → lower.** Still untested, and back in play since **MakeIt does not use the
   serial path** for jobs (it uploads to SD over the USB network gadget), so it never demonstrated
   the serial link reliable
3. **CH340 re-enumeration** — the port moved COM6 → COM9. Device Manager → *Show hidden devices*,
   count ghost entries. Would sit underneath everything else
4. **Blank the `Air On` / `Air Off` templates** — `M8` is rejected by the firmware and is still in
   every job
5. **`Enable Q-Pulse Options`** — the toggle exists on the Custom GCode device class. If it exposes
   per-layer pulse width, MOPA becomes first-class and `docs/09` needs rewriting
6. **The upload bridge** over `192.168.42.1` — what MakeIt actually does, and the only architecture
   that avoids the acknowledgement protocol entirely

## Workaround that already exists

`tools/derelativize-gcode.ps1` converts a saved `.gc` from relative to absolute, then send it with
**Run GCode**. Does not fix stalls; makes them survivable. Validated — output coordinate range
matches the job's declared bounds exactly.

## Practical notes for whoever picks this up

- **Identify a LightBurn device by the `;` header of its emitted G-code, never by DisplayName.**
  Two device classes can share a name. That mistake cost an afternoon and is written up in
  `captures/stage4-which-device-are-we-testing.md` rather than hidden
- Profiles are generated: edit `tools/profile-spec.json`, run `tools/build-profiles.ps1`,
  `tools/validate-lbdev.ps1` must pass
- `M18S0` lives in the profile's **User Start Script**, not `StartGCode` (which this device class
  ignores). `M15S0` in User End Script stops the fan
- Air assist **off** — `M8` is rejected, and off still emits `M9` twice
- **Frame can fire the beam.** Not a gantry laser; the habit does not transfer
- Machines: **cortex** = dev workstation (repo lives here, share is `\\cortex\D`),
  **benchy** = basement PC with the laser on USB. Launcher: `\\cortex\D\lumos.cmd`, option `p`
  grabs `prefs.ini`
- Raw capture video is gitignored (`docs/images/*.mp4`) and stays local — it was stripped from
  history once already
