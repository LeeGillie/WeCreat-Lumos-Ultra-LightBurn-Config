# 02 — Feature & Mode Inventory

The master status list. Every Lumos Ultra capability, what it would take to reach it from
LightBurn, and where we actually are.

**Status vocabulary**

| Status | Meaning |
|---|---|
| ⬜ `NOT-STARTED` | Nobody has looked at it yet |
| 🟨 `DRAFT` | A draft profile or approach exists, untested on hardware |
| 🟦 `NEEDS-HW` | Design is settled; blocked only on someone with the machine running a test |
| 🟥 `BLOCKED-LB` | Blocked by LightBurn — the feature is galvo-class only and this is a GRBL device |
| 🟥 `BLOCKED-FW` | Blocked by WeCreat firmware — the capability is not exposed to third parties |
| 🟩 `WORKING` | Confirmed working on a physical Lumos Ultra by at least one contributor |

Nothing is 🟩 yet. This project is pre-hardware.

---

## A. Laser sources

| # | Feature | Detail | Status | Notes |
|---|---|---|---|---|
| A1 | 6 W UV source | 355 nm, spot 0.0019 mm | 🟨 `DRAFT` | Base source, ships with every Ultra |
| A2 | 60 W MOPA fiber | JPT module, add-on | 🟨 `DRAFT` | Same red lens as A3 |
| A3 | 100 W MOPA fiber | JPT module, add-on, spot 0.03 mm | 🟨 `DRAFT` | |
| A4 | UV ↔ MOPA source switching | WeCreat: "one click, no machine swapping" | 🟦 `NEEDS-HW` | Lumos uses `M18S1`/`M18S0`. Ultra code **unknown** — do not assume. [Open Q3](#open-questions) |
| A5 | MOPA frequency (PRR) control | | 🟥 `BLOCKED-LB` | LightBurn exposes Frequency only on galvo devices. Custom G-code only, if a code exists |
| A6 | MOPA Q-pulse width (ns) | The main reason to want MOPA | 🟥 `BLOCKED-LB` | Same. **This is the project's biggest disappointment** — see [09](09-k9-and-mopa-limits.md) |
| A7 | UV min/max pulse | | 🟥 `BLOCKED-LB` | Galvo-class `UV Min Pulse` / `UV Max Pulse` fields do not exist for GRBL devices |
| A8 | Power (S value) | | 🟨 `DRAFT` | Ordinary GRBL. `S_Scale: 1000` per vendor profiles |
| A9 | Speed (F value) | | 🟨 `DRAFT` | Ordinary GRBL |

## B. Field lenses

| # | Lens | Working area | Status | Notes |
|---|---|---|---|---|
| B1 | **Purple** — general UV, flat & cylindrical | 210 × 210 mm | 🟨 `DRAFT` | `WeCreat-Lumos-Ultra-UV-Purple-210.lbdev` |
| B2 | **Green** — K9 crystal internal | 70 × 70 mm field; 70 × 70 × 135 mm volume | 🟨 `DRAFT` | Surface marking through the green lens may work; internal 3D will not — see F4/F5 |
| B3 | **Red** — MOPA fiber (60 W and 100 W share it) | 210 × 210 mm | 🟨 `DRAFT` | Two profiles, one per wattage, so material libraries stay separate |
| B4 | Per-lens optical correction (scale/bulge/skew/trapezoid) | | 🟥 `BLOCKED-LB` | Galvo Device Settings only. On GRBL the controller's own correction is all you get |
| B5 | Field-lens auto-detection | WeCreat advertises it | 🟥 `BLOCKED-FW` | LightBurn will not switch profiles when you swap a lens. Mitigation: per-profile start-of-job **Checklist** — see [12-checklists.md](12-checklists.md) |

## C. Work modes

These nine modes are enumerated directly from the shipping MakeIt! 3.0.6 application bundle
(`images/lumosUltraWorkMode/`) — this is the vendor's own list for *this machine*, not marketing
copy. See [11-makeit-internals.md](11-makeit-internals.md) for method. **CONFIRMED-vendor.**

| # | MakeIt mode | What it is | LightBurn equivalent | Status |
|---|---|---|---|---|
| C1 | `plane-mode` | Flat surface marking | Ordinary job | 🟨 `DRAFT` |
| C2 | `cylinder-mode` | Cylindrical objects (rotary) | Rotary setup, A axis | 🟦 `NEEDS-HW` |
| C3 | `emboss-mode` | Relief / depth-map engraving | 3D Sliced Image mode | 🟥 `BLOCKED-LB` |
| C4 | `crystal-mode` | K9 internal engraving, 2D layer | — | 🟦 `NEEDS-HW` (probably 🟥) |
| C5 | `crystal-mode3D` | K9 internal volumetric | — | 🟥 `BLOCKED-FW` |
| C6 | `autoslider-mode` | Slide Extension, flat | Split Marking (galvo-only) or manual tiling | 🟥 `BLOCKED-LB` for automatic; manual tiling 🟦 `NEEDS-HW` |
| C7 | `autosliderCylinder-mode` | Slide + rotary, long cylinders | — | 🟥 `BLOCKED-LB` |
| C8 | `conveyorbelt-mode` | AutoFlow conveyor batch feeding | — | 🟦 `NEEDS-HW` |
| C9 | `conveyorBeltSlide-mode` | Conveyor + slide combined | — | 🟥 `BLOCKED-LB` |

The generic (non-Ultra) MakeIt mode set also contains `baseplate-mode`, `curve-mode` and
`manualhand-mode`; these are not present in the Ultra-specific asset folder and may or may not
apply to the Ultra.

## D. Accessories

| # | Accessory | Spec | Status | Notes |
|---|---|---|---|---|
| D1 | Rotary Pro | Chuck 3–100 mm, sphere/ring 10–37 mm, tilt 0–180° | 🟦 `NEEDS-HW` | WeCreat lists LightBurn as supported software for the Rotary Pro — but on a page whose compatibility row says "Lumos / Lumos Flex", not Ultra |
| D2 | Slide Extension | 520 × 183 mm working area | 🟦 `NEEDS-HW` | Motor addressing unknown. Automatic split marking is `BLOCKED-LB` |
| D3 | Rotary + Slide combo | Up to 380 mm long, 100 mm dia | 🟥 `BLOCKED-LB` | Nobody has ever made rotary+slide work in LightBurn on *any* Lumos |
| D4 | AutoFlow Conveyor | 10 kg load. Vendor quotes three different working areas — 206 × 206 mm/cycle, 200 × 500 mm, and 1000 × 200 mm total feed | 🟦 `NEEDS-HW` | Precedent: the Vision passthrough conveyor is driven as an **A axis** through LightBurn's rotary setup |
| D5 | AirGuard Ultra 2.0 extractor | | ⬜ `NOT-STARTED` | Likely independent of LightBurn |
| D6 | Thermoelectric cooling base | | ⬜ `NOT-STARTED` | Likely independent |
| D7 | FreeFlow air assist | | 🟦 `NEEDS-HW` | No WeCreat air-assist M-code has ever surfaced publicly |

## E. Machine functions

| # | Function | Status | Notes |
|---|---|---|---|
| E1 | USB connection | 🟦 `NEEDS-HW` | **Port confirmed on hardware** — CH340 bridge at COM7 (`VID_1A86&PID_7523`), plus an RNDIS gadget on the same internal hub. Still needs LightBurn actually talking over it (Stage 3) |
| E2 | Wi-Fi connection | 🟥 `BLOCKED-FW` | Ultra spec says USB/Wi-Fi, but Wi-Fi is a MakeIt path. No evidence LightBurn can use it |
| E3 | Ethernet | — | Not documented on the Ultra at all |
| E4 | Autofocus | 🟦 `NEEDS-HW` | Vision family: `M130X<mm>Y<mm>` as a macro or as LightBurn's Focus Z command. Ultra code unverified |
| E5 | Red-dot framing | 🟦 `NEEDS-HW` | `M21S1` / `M21S0` on the Vision family |
| E6 | Z axis / focus height | 🟦 `NEEDS-HW` | Vendor Lumos profile has `EnableZ: false`; Vista and Vision Pro have it `true`. Ultra unknown. Drafts ship with Z **disabled** for safety |
| E7 | Homing | 🟦 `NEEDS-HW` | `HomeOnStartup: false` in every vendor profile |
| E8 | Exhaust fan | 🟦 `NEEDS-HW` | `M15S1` / `M15S0` on the Vision family — the best-attested WeCreat code after `M130` |
| E9 | Laser module fan | 🟦 `NEEDS-HW` | `M14S1` / `M14S0` on the Vision family; **absent from the Lumos profile** |
| E10 | Lid interlock | 🟩 vendor-side | Enforced by the controller, not the software. **The REST command endpoint bypasses it** |
| E11 | "U mode" (`M16` / `M17`) | 🟥 `UNKNOWN` | Present in the start G-code of *every* WeCreat profile, so it is fundamental. Nobody knows what it is. See [04](04-mcode-dictionary.md#what-is-u-mode) |

## F. Cameras & imaging

| # | Feature | Status | Notes |
|---|---|---|---|
| F1 | Camera positioning in LightBurn | 🟦 `NEEDS-HW` | LightBurn 2.1 ships a **WeCreat camera preset**; camera arrives over RNDIS as an `LBHTTP:` device. Lens calibration must be set to "(None – precalibrated camera)" |
| F2 | Number of cameras | 🟩 **ANSWERED** | **One accessible camera.** `/camera/take_photo` returns a single wide-angle JPEG, not a composite; the controller config names one device, `/dev/video0`; no second endpoint exists. Image arrives **rotated ~90° and lens-uncorrected**. The "16K" figure is an **engraving resolution** claim, not a camera spec |
| F3 | Dual-camera / wall view (LightBurn 2.1) | 🟥 `BLOCKED-FW` | F2 resolved to one accessible stream — there is no second feed to attach |
| F4 | Smart Fill / batch layout | 🟥 `BLOCKED-FW` | On-machine feature, no third-party path |
| F5 | Material recognition | 🟥 `BLOCKED-FW` | |

## G. Cross-cutting LightBurn features

| # | Feature | Status | Notes |
|---|---|---|---|
| G1 | Per-device start-of-job **Checklist** | 🟨 `DRAFT` | Our lens-confirmation safeguard. `"Checklist"` is a top-level key in the `.lbdev` |
| G2 | Material libraries per source | ⬜ `NOT-STARTED` | Wanted: separate libraries for UV, MOPA 60, MOPA 100 |
| G3 | `.lbzip` User Bundle distribution | ⬜ `NOT-STARTED` | LightBurn 2.x exports `.lbzip`; `.lbdev` is import-only legacy. Bundle can carry devices + material libraries + presets |
| G4 | Fill throughput over serial | 🟦 `NEEDS-HW` | Expect fills far below the machine's 16,000 mm/s headline. Needs a benchmark against MakeIt |

---

## Open questions

1. ~~**Does the Ultra present as a GRBL serial device?**~~ — **ANSWERED 2026-08-24: yes.**
   A physical Ultra enumerates as a CH340 serial bridge (`VID_1A86&PID_7523`, COM7) plus a Linux
   RNDIS gadget (`VID_0525&PID_A4A2`), with no galvo controller present. The RNDIS link comes up
   on `192.168.42.0/24`. See [01-architecture.md §4](01-architecture.md#4-confirmed-on-a-physical-lumos-ultra--2026-08-24).
2. ~~**What is the Ultra's serial banner and baud rate?**~~ — **ANSWERED 2026-08-24.**
   `$I` returns **`[WeCreat Lumos :ver 000240]`** — note it does **not** say "Ultra" — at
   **1,000,000 baud**. No unsolicited banner on port open; it is emitted on power-up only.
   See [capture](../captures/stage1-serial-benchy.md).
3. **What M-code selects UV vs MOPA on the Ultra?** *Test: Stage 5, differential MakeIt capture.*
4. **Is there any G-code for MOPA pulse width / frequency?** *Test: Stage 5.*
5. **What is "U mode"?** *Test: firmware strings, or differential capture.*
6. ~~**Is the REST API on :8080 unchanged on the Ultra?**~~ — **ANSWERED 2026-08-24: present.**
   Ports 22, 8080 and 8082 are all open on `192.168.42.1`. `/camera/take_photo` returns an
   826 KB JPEG, `/device/camera/download` returns calibration JSON, `/process/status` answers —
   though its response shape has changed from the Vision generation. **A `weburn`-style bridge
   is viable on this machine.** See [capture](../captures/stage2-rest-benchy.md).
7. **How are the slide and conveyor motors addressed — A axis, U axis, or remapped Y?**
   *Test: Stage 7/8 differential capture.*
8. ~~**Does `$$` work?**~~ — **ANSWERED 2026-08-24: no.** The controller acknowledges `$$` with a
   bare `ok` and returns nothing. `$#` and `$G` are likewise stubs; `?` and `$I` are fully
   implemented. **Field size and scaling therefore cannot be read from the machine and must be
   measured** (Stage 4). See [capture](../captures/stage1-serial-benchy.md).
9. **Does the Ultra's field really measure 210 × 210 mm?** Now the highest-value unknown, since
   the controller will not tell us. *Test: Stage 4 framing with calipers.*
10. **Is `Pn:Z` (Z limit asserted at rest) normal, or a stuck input?** Matters before enabling Z
    or homing.

Each carries a matching issue label. If you can answer one, you have moved this project further
than any amount of documentation work.
