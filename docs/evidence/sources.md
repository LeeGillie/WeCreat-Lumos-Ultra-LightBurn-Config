# Evidence & Sources

Every non-obvious claim in this repository should be traceable to something here. If you add a
claim, add its source. If you find a source that contradicts one of ours, open an issue — that is
the most useful kind of contribution.

Retrieved **2026-08-24** unless noted.

---

## Primary artifacts we inspected directly

| Artifact | What it gave us |
|---|---|
| `WeCreat-Lumos-v1.5.lbdev` (WeCreat CDN, `?v=1754041991` → 2025-08-01) | `"Name":"GRBL"`, `"Type":"Serial"`, baud 1 000 000, 116 × 116 mm, `MirrorY`, `S_Scale`, `CutOrigin`, rotary keys, the Lumos start block, and the `M18`/`M1` macro labels |
| `WeCreat-Vision-V1.0.lbdev`, `WeCreat-Vision_Pro-V1.0.lbdev`, `WeCreat-Vista-V1.0.lbdev`, `WECREAT-LC.lbdev` | The Vision-family start/end blocks and the `M130`/`M21`/`M16`/`M17` macro labels; baud 500 000 |
| `MakeIt!/resource/driver/win/rndis/rndis11.inf` (MakeIt 3.0.6, installed) | `USB\VID_0525&PID_a4a2` and `USB\VID_1d6b&PID_0104&MI_00` — the machine is a Linux USB gadget |
| `MakeIt!/resources/app.asar` (MakeIt 3.0.6, installed) | The nine `lumosUltraWorkMode/` assets; Electron; encrypted `f.enc`; bytenode `.jsc` |
| `MakeIt!/resources/app-update.yml` (MakeIt 3.0.6, installed) | Updater points at GitHub `yuerugoutql/makeit-builder` |

Vendor `.lbdev` files are fetched by `tools/fetch-vendor-lbdev.ps1` into gitignored `reference/`
and are **not redistributed** here.

## WeCreat — official

- Lumos Ultra product page — https://wecreat.com/products/lumos-ultra-6w-uv-60w-100w-mopa-laser-engraver
- MOPA add-on module — https://wecreat.com/products/60-100w-mopa-laser-module-for-lumos-ultra
- Slide Extension — https://wecreat.com/products/slide-extension-for-lumos-ultra
- AutoFlow Conveyor — https://wecreat.com/products/auto-flow-conveyor
- Rotary Pro — https://wecreat.com/products/rotary-for-wecreat-lumos
- Software / LightBurn downloads — https://wecreat.com/pages/software
- **Instructions on Direct LightBurn Connection** ("Only USB connection is supported") — https://support.wecreat.com/hc/en-us/articles/9633347845519
- How do I Fix the USB Connection Problem? (RNDIS + CH340 in Device Manager) — https://support.wecreat.com/hc/en-us/articles/9775153916431
- How to Install USB Driver on the PC (`Resource > driver > win > rndis`) — https://support.wecreat.com/hc/en-us/articles/9081963351055
- Lumos Connection-Related Issue — https://support.wecreat.com/hc/en-us/articles/13440470222479
- Lumos Firmware-Related Issue (`.tar.gz` OTA) — https://support.wecreat.com/hc/en-us/articles/13489263547407
- Force OTA Guide — https://support.wecreat.com/hc/en-us/articles/9608509396367
- Software Version Information (MakeIt changelog, tops out at 3.0.2) — https://support.wecreat.com/hc/en-us/articles/9089646406159
- Tips for using LightBurn with WeCreat Lasers — https://support.wecreat.com/hc/en-us/articles/10560668639759
- Auto-pass Through Feeder with LightBurn (conveyor as **A axis**) — https://support.wecreat.com/hc/en-us/articles/10159360297231
- Tumbler engraving with LightBurn ("Set Axis to A") — https://support.wecreat.com/hc/en-us/articles/12836359966351
- Camera Calibration with LightBurn — https://support.wecreat.com/hc/en-us/articles/10662689424783
- Kickstarter campaign + FAQ — https://www.kickstarter.com/projects/wecreat/lumos-ultra-worlds-first-one-stop-uv-mopa-laser/faqs

## LightBurn — official

- Devices window (import/export, `.lbdev` import-only in 2.x) — https://docs.lightburnsoftware.com/2.1/Reference/Devices/
- User Bundles (`.lbzip` contents) — https://docs.lightburnsoftware.com/2.1/Reference/UserBundles/
- Vendor Bundles (`.lbvendor`) — https://docs.lightburnsoftware.com/legacy/Vendor/VendorBundles
- Managing Preferences (`.lbprefs`) — https://docs.lightburnsoftware.com/2.1/Reference/ManagingPreferences/
- Machine Settings (`.lbset`) — https://docs.lightburnsoftware.com/2.1/Reference/MachineSettings/
- Add a Galvo Laser (JCZFiber / BSLFiber / EZCad3; "USB is currently the only supported type for Galvo devices") — https://docs.lightburnsoftware.com/2.1/GetStarted/AddGalvo/
- Device Settings — Galvo and Basic Settings (field, red dot, scale/bulge/skew/trapezoid, timings) — https://docs.lightburnsoftware.com/2.1/Reference/DeviceSettings/GalvoBasicSettings/
- Device Settings — Ports and Laser Settings (Laser Type CO2/Fiber/UV/SPI, Enable Q-Pulse Width, UV Min/Max Pulse) — https://docs.lightburnsoftware.com/2.1/Reference/DeviceSettings/GalvoPorts/
- Galvo-Specific Cut Settings (**Frequency**, **Q-Pulse Width**, 3D Sliced Image Mode) — https://docs.lightburnsoftware.com/2.1/Reference/CutSettingsEditor/GalvoSpecificCutSettings/
- Galvo Lens Calibration — https://docs.lightburnsoftware.com/2.1/Reference/CalibrateGalvoLens/
- Rotary Mode (Galvo) — https://docs.lightburnsoftware.com/2.1/Reference/RotaryMode/RotaryModeGalvo/
- Split Marking (2.1, galvo-only, external axis table) — https://docs.lightburnsoftware.com/2.1/Reference/SplitMarking/
- What's New in 2.1 — https://docs.lightburnsoftware.com/2.1/NewFeatures/NewIn2.1/
- Add A Camera / Camera Selection (WeCreat preset; RTSP not supported) — https://docs.lightburnsoftware.com/2.1/Reference/Cameras/AddACamera/ · https://docs.lightburnsoftware.com/2.1/Reference/Cameras/CameraSelection/
- **WeCreat Camera Calibration and Alignment** — https://docs.lightburnsoftware.com/2.1/Guides/WeCreatCameraAlignment/
- 1.7.00 release notes ("Initial WeCreat Vision camera support over RNDIS") — https://lightburnsoftware.com/blogs/news/lightburn-1-7-00
- 2.1 release notes ("Allow for extra ok's from WeCreat firmware") — https://lightburnsoftware.com/blogs/news/lightburn-2-1-quick-nest-enhanced-camera-support-undo-history-and-more
- 2.1.02 patch notes ("WeCreat device detection / messaging fix", "Reverted LightBurn GRBL Protocol to GRBL-ish") — https://lightburnsoftware.com/blogs/news/lightburn-2-1-02-patch-release

## Reverse engineering

- **`2ktsch/weburn`** — WeCreat Vision → LightBurn bridge. REST endpoints, MD5 scheme, M-code constants, camera shim, and the *"THIS GCODE WILL RUN REGARDLESS OF THE LID POSITION"* warning — https://github.com/2ktsch/weburn
- weburn discussion thread — https://forum.lightburnsoftware.com/t/weburn-wecreat-vision-to-lightburn-compatibility-bridge/135403

## Community — the load-bearing threads

- **Lumos is "some variant of a GRBL device"** (LightBurn staff), plus "we only discovered the Lumos after it had already launched" and WeCreat "didn't hear back" — https://forum.lightburnsoftware.com/t/possible-to-use-wecreat-lumos-rotary-combined-with-slide-extension-in-lightburn/179528
- **Depth maps do not work on the Lumos even with Pro** — "it uses GRBL... not a real galvo control laser and can't use depth map due that" — https://forum.lightburnsoftware.com/t/deep-engraving-wecreat-lumos/181803
- **Serial banner** `[WeCreat Lumos :ver 000207]` with extra `ok`s — https://forum.lightburnsoftware.com/t/wecreat-lumos-busy-and-not-finding-my-laser/179777
- **`M130X…Y…` autofocus**, and the Focus Z button only existing on Custom GCode + GRBL devices — https://forum.lightburnsoftware.com/t/focus-z-button-for-wecreat-shown-in-the-wecreat-camera-calibration-video/153627
- WeCreat + LightBurn starter guide (community) — https://forum.lightburnsoftware.com/t/wecreat-using-lightburn-starter-guide/138723
- **`M15S1`/`M15S0` = exhaust fan; `M130X50Y50` = autofocus** — https://thetinkerverse.com/lets-talk-about-the-wecreat-vision-40w/
- Lumos camera works in LightBurn (rotated 90°) — https://forum.lightburnsoftware.com/t/lumos-camera-setup/186137
- Vision passthrough conveyor as A axis — https://forum.lightburnsoftware.com/t/wecreat-vision-with-passthrough-conveyor-a-axis-not-working/158871
- **LightBurn cannot switch Lumos laser sources** — https://grouchyfarmer.com/2025/12/27/wecreat-lumos-dual-laser-engraver-follow-up-questions-etc/
- AlgoLaser `M16`/`M17` = air pump — **contrast case, do not import** — https://forum.lightburnsoftware.com/t/algolaser-air-assist-how-to-use-m16-m17-effectively/127992

## Press & reviews (used only for specs, never for protocol)

- PR Newswire launch — https://www.prnewswire.com/news-releases/wecreat-launches-lumos-ultra-on-kickstarter-the-worlds-first--only-one-stop-6w-uv--60w100w-mopa-laser-system-302709013.html
- Hackster — https://www.hackster.io/news/wecreat-s-lumos-ultra-delivers-multi-material-high-speed-etching-with-dual-uv-and-mopa-lasers-95c89af78fc1
- HobbyLaserCutters review (lens focal lengths; 3D modes are MakeIt-only) — https://hobbylasercutters.com/wecreat-lumos-ultra-review/
- GizmoCrowd — https://www.gizmocrowd.com/post/wecreat-lumos-ultra-laser-engraver-review
- MakeTechCreate — https://maketechcreate.com/blogs/video-tutorials/wecreat-lumos-ultra-review-uv-mopa-laser-engraver-tested-on-wood-metal-glass-more
- Tom's Hardware, WeCreat Lumos (116 × 116 mm field) — https://www.tomshardware.com/maker-stem/wecreat-lumos-review

---

## Known gaps in our own research

Stated so nobody assumes these were checked:

- **Reddit** was not searched (r/lasercutting, r/fiberlasers). Likely place for an early Ultra owner report.
- **YouTube** descriptions, comments and transcripts of Ultra review videos were not read.
- **GitHub code search** was unavailable — no search for `M18S1`, `M57A`, `M107X`, `M130X` in a WeCreat context, and `weburn`'s forks and issues were not enumerated.
- **FCC ID filings** were not retrieved. **FCC internal photos are the best public route to a definitive answer on the controller board** and should be someone's next move.
- **Facebook groups and Discord** are not indexed.
- The **LightBurn forum's own search** is robots-disallowed; we enumerated the WeCreat category but cannot rule out an Ultra thread elsewhere.
- Whether **`yuerugoutql/makeit-builder`** on GitHub is public.

Any of these could be closed by a contributor in an afternoon.
