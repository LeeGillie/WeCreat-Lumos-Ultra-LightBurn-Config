# 01 — Architecture: what the Lumos Ultra actually is, from LightBurn's point of view

**Evidence grades used throughout this repository**

| Grade | Meaning |
|---|---|
| **CONFIRMED-vendor** | Stated or demonstrated by WeCreat's own artifacts — a shipped file, a support article, the application bundle |
| **CONFIRMED-community** | An owner or reviewer reports the observed behaviour from testing |
| **INFERRED** | Deduced from adjacent confirmed facts. Plausible, not proven |
| **UNKNOWN** | Present in vendor output, or required by the project, with no established meaning |

---

## 1. The headline

LightBurn talks to WeCreat machines as **GRBL-flavoured G-code over a serial port**. Not as a
galvo controller.

This is not a guess. WeCreat's own `WeCreat-Lumos-v1.5.lbdev` — the profile for the Ultra's
closest sibling, which is *also* a galvo-optics machine — contains:

```json
"Name": "GRBL",
"Type": "Serial",
"Width": 116,
"Height": 116,
"MirrorY": true,
"Settings": {
    "BaudRate": 1000000,
    "S_Scale": 1000,
    "CutOrigin": 2,
    "EnableZ": false,
    ...
}
```

`"Name"` is the LightBurn **driver type**. `"Type"` is the **connection**. Every one of WeCreat's
four published profiles — Vision, Vision Pro, Vista, Lumos — says `"Name": "GRBL"`.
**CONFIRMED-vendor.**

LightBurn's own staff have said the same thing about the Lumos in public: it is "some variant of
a GRBL device, so the Core version of LightBurn is what you need."

## 2. Why a galvo machine speaks G-code

Because the galvo timing does not happen on your PC. The controller is a two-tier system:

```
   PC                       machine
 ┌──────────┐   USB     ┌──────────────────────────────────────┐
 │ LightBurn│──────────▶│  Linux SBC          ──▶   MCU        │
 │  MakeIt  │  serial   │  (REST :8080,             (galvo     │
 └──────────┘  + RNDIS  │   camera, files,           timing,   │
                        │   SSH :22)                 motion)   │
                        └──────────────────────────────────────┘
```

Evidence for the two tiers:

- WeCreat's bundled RNDIS driver (`resource/driver/win/rndis/rndis11.inf`, shipped inside MakeIt!)
  binds these hardware IDs: **CONFIRMED-vendor**
  ```
  USB\VID_0525&PID_a4a2                 ; Linux/NetChip USB Ethernet gadget
  USB\VID_1d6b&PID_0104&MI_00           ; Linux Foundation multifunction composite gadget
  ```
  `1d6b` is the Linux Foundation vendor ID and `0104` is the multifunction composite gadget —
  i.e. **the machine presents itself as a Linux USB gadget**, and `MI_00` means it is a composite
  device with more than one interface. That is how one cable can carry both a network interface
  and a serial interface.
- The reverse-engineered REST endpoint for sending a single command is literally
  **`POST /test/cmd/mcu`** — the SBC forwards to an MCU. **CONFIRMED-community** (via the
  `weburn` project, Vision generation).
- WeCreat distributes firmware as a **`.tar.gz`** side-loaded through a hidden MakeIt console —
  a Linux userland payload, not a galvo card image. **CONFIRMED-vendor.**

So LightBurn hands the MCU high-level geometry; the MCU does the galvo interpolation. The
machine's headline 16,000 mm/s is therefore *not* evidence against a G-code link for vector
work. It is a real concern for **fills**, where LightBurn's GRBL output modulates power per
pixel over an ack-per-line link. The Lumos profile's macros `M1S1` ("svg") and `M1S0` ("BMP")
look like a controller-side mode switch bolted on for exactly this reason. **INFERRED.**

## 3. What this costs us

LightBurn gates a large set of features behind its **galvo** device class. On a device typed
`GRBL`, they simply do not exist in the UI:

| LightBurn feature | Available on a GRBL-typed device? | Consequence for the Ultra |
|---|---|---|
| **Q-Pulse Width** (MOPA ns pulse control) | **No** — galvo-only cut setting | MOPA pulse width is not reachable from LightBurn's UI. Would have to be smuggled in as custom G-code, if an M-code for it even exists |
| **Frequency (kHz)** as a cut setting | **No** — galvo-only | Same |
| Lens correction: **Scale / Bulge / Skew / Trapezoid** | **No** — galvo Device Settings only | Per-lens optical correction cannot be entered. Whatever correction the controller applies internally is what you get |
| **Galvo Rotary Mode** (chuck/roller, steps-per-rotation) | **No** — but GRBL rotary **is** available | Use LightBurn's ordinary rotary setup on the A axis. WeCreat's own guide for other models says "Set Axis to **A**" |
| **Split Marking** (2.1, galvo-only) | **No** | The Slide Extension cannot be driven by LightBurn's split-marking engine |
| **3D Sliced / depth-map image mode**, 16-bit depth maps | **No** | Confirmed failure on the Lumos even with LightBurn Pro. This removes relief/emboss work from LightBurn |
| **Red Dot offsets / rest position** | **No** | Framing behaviour is whatever the controller does; `M21S1` may toggle the pointer |
| Speed, power, passes, interval, hatch angle, cross-hatch | **Yes** | Ordinary GRBL cut settings work normally |
| Camera | **Yes**, via LightBurn's `LBHTTP:` WeCreat camera path | See [08-cameras.md](08-cameras.md) |

**For a 100 W MOPA owner this is the sharp edge of the whole project.** The reason to want
LightBurn for MOPA work is precisely frequency and pulse-width control, and that is the feature
LightBurn's GRBL class does not have. Read [09-k9-and-mopa-limits.md](09-k9-and-mopa-limits.md)
before deciding how much to invest here.

## 4. What we still do not know about the **Ultra** specifically

Everything above is confirmed for the **Lumos** and the Vision family. Nobody has publicly
connected a **Lumos Ultra** to LightBurn — the machine began shipping in July 2026 in small
numbers, and there is not one Lumos Ultra thread in LightBurn's own WeCreat forum category.

The Ultra is *strongly* expected to be the same architecture because:

- WeCreat's Ultra spec sheet lists the same "USB / Wi-Fi" connection method as the Lumos.
- MakeIt! ships as iOS / iPadOS / Android apps as well as desktop — a phone cannot host a
  PC-tethered galvo card, so the marking engine must live in the machine.
- The Ultra has on-machine features no PC-hosted galvo card provides: 50 MP camera batch fill,
  autofocus, field-lens auto-detection, on-board project library, one-button start.
- MakeIt! 3.0.6 ships Ultra assets alongside the Lumos ones in the same application, with the
  same code path. See [11-makeit-internals.md](11-makeit-internals.md).

But it is inference. **The falsifying test is trivial and takes two minutes:** see
[03-bringup-plan.md](03-bringup-plan.md) Stage 0.

## 5. The two possible integration paths

### Path A — native LightBurn GRBL device *(primary)*

Create a GRBL/Serial device profile, connect over the machine's USB serial interface, and drive
it the way the Lumos is driven today. This is what `profiles/draft/` targets.

Cost: no camera-driven autofocus beyond an `M130`-style macro, no MOPA pulse control, no relief.
Benefit: works today with stock LightBurn, no extra software.

### Path B — bridge to the REST API *(secondary, richer)*

The `weburn` project (Vision 20 W only) proved a bridge can present a virtual serial port to
LightBurn and translate to the machine's HTTP API on port 8080, gaining camera stills and
autofocus probing that the serial path cannot reach. Endpoints documented in
[05-connectivity.md](05-connectivity.md).

Cost: extra moving part, null-modem driver, and the REST command endpoint **fires the laser
regardless of lid position** — a genuine safety hazard, see [SAFETY.md](../SAFETY.md).
Benefit: access to camera, autofocus measurement, bulk job upload (which sidesteps the fill
throughput problem entirely by letting the controller run the job).

A mature version of this project probably ships **both**: a plain profile for everyday work, and
an optional bridge for the features the serial path cannot reach.

## 6. Open architectural questions

1. Does the Ultra enumerate as a serial device at all, and at what baud? *(Stage 0)*
2. Is the Ultra's serial endpoint the MCU directly, or a CDC-ACM gadget on the SBC? This changes
   where a bridge would hook in.
3. Are ports 8080 / 8082 / 22 still open on the Ultra, and is the endpoint map unchanged?
4. Does the Ultra implement GRBL `$$` settings at all? No WeCreat machine has ever had its `$$`
   output published.
5. How is UV↔MOPA source selection commanded? The Lumos uses `M18S1`/`M18S0` for its two
   sources. The Ultra has UV, MOPA, *and* a red pointer, so the code may differ.
6. Is there any G-code path to MOPA pulse width and frequency?

Each of these has a concrete test in [03-bringup-plan.md](03-bringup-plan.md).
