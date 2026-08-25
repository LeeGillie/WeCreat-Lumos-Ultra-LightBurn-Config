# 08 — Cameras

## Good news first

**LightBurn already has WeCreat camera integration.** This is one of the few areas where the
groundwork is done for us:

- LightBurn **1.7.00**: *"Initial WeCreat Vision camera support over RNDIS."*
- LightBurn **2.1** ships a built-in **WeCreat camera preset** (alongside Creality Falcon A1 Pro,
  Thunder Laser Vision, xTool P2).
- LightBurn maintains a dedicated guide: *WeCreat Camera Calibration and Alignment*.
- The Lumos's internal camera is confirmed working in LightBurn today by owners (rotated 90°,
  fixed via Camera Alignment).

WeCreat's own FAQ: *"Why am I unable to see or select WeCreat camera?" → "Please ensure the
LightBurn version is 1.7.00 or above."* Camera support additionally needs machine firmware
≥ 2.0.24.

## How it works

The camera is **not a USB webcam**. It arrives over the RNDIS virtual network link as an HTTP
image source. LightBurn's device profiles name it with an `LBHTTP:` prefix — the vendor Lumos
profile carries `"LastCamera": "LBHTTP: WeCreat Vision"`, and the Vision Pro profile
`"LBHTTP: WeCreat Camera"`.

`LBHTTP:` is LightBurn's internal "fetch JPEG stills over HTTP" camera driver. It almost
certainly maps to `GET http://<rndis-ip>:8080/camera/take_photo` — the only endpoint that returns
an image, and the resolutions line up. **INFERRED**, not documented by LightBurn.

**Critical setup detail:** LightBurn's lens calibration must be set to
**"(None – precalibrated camera)"**, because the WeCreat controller corrects lens distortion
itself before serving the frame. Running LightBurn's own lens correction on top double-corrects
and produces nonsense. The controller's calibration data is retrievable at
`GET /device/camera/download` (3×3 point grids at three heights, plus focal lengths).

Frame rate is low — the `weburn` author measured roughly 3–4 fps polling stills.

## How many cameras does the Ultra have? — ANSWERED

**One accessible camera. CONFIRMED-hardware, 2026-08-24.**

Three independent observations on a physical Ultra
([capture](../captures/stage2-rest-benchy.md)):

1. `GET http://192.168.42.1:8080/camera/take_photo` returns **a single 826 KB JPEG** — one
   wide-angle frame of the bed, **not** a composite or a stereo pair.
2. The controller's own `/etc/mbtc/cfgs.json` names exactly one capture device:
   `"videoid":"/dev/video0"`.
3. No second camera endpoint was found on the API.

If the Ultra contains more than one physical sensor, **only one is exposed**, and only one is
therefore usable from LightBurn or from a bridge. LightBurn 2.1's dual-camera "wall view" has
nothing to attach a second feed to.

Two further observations from the captured frame, both matching known Lumos behaviour:

- **The image is rotated roughly 90°** relative to the bed. Lumos owners report the same, and fix
  it with LightBurn's Camera Alignment rather than by rotating the source.
- **The frame is raw wide-angle and visibly barrel-distorted** — the enclosure walls curve. So
  this endpoint serves an *uncorrected* image, even though LightBurn's WeCreat workflow expects a
  precalibrated feed and tells you to set lens calibration to "(None – precalibrated camera)".
  Whether LightBurn's `LBHTTP:` path requests a different, corrected stream is **UNKNOWN** and
  worth establishing before trusting camera alignment.

### What WeCreat publishes, for contrast

Every published reference is singular: "HD Camera" in the spec table, "Built-in 50 MP Camera" in
listings.

Two figures get conflated in coverage of this machine, and it is worth separating them:

| Figure | What it actually refers to |
|---|---|
| **50 MP** | The camera, specifically in connection with **Smart Fill** batch layout |
| **16K** | **Engraving/image resolution** — it appears under the spec row "Image Resolution" and in the heading "Ultra-fine 16K Precision Engraving". **It is not a camera spec** |

If the Ultra does have two internal cameras, the question that matters for LightBurn is whether
they present as **two separately addressable streams** or are merged by the controller into one
composite image. LightBurn 2.1 added multi-camera and "wall view" support, so two streams would
be usable in principle — but only if the controller exposes them.

**This is testable at Stage 2:** poll `/camera/take_photo` and see what comes back, and look for
any second camera endpoint.

## Camera capabilities worth having, and their odds

| Capability | Odds from LightBurn | Why |
|---|---|---|
| Camera overlay / positioning | **Good** | Preset exists, precedent on the Lumos |
| Camera-assisted alignment of artwork to a part | **Good** | Standard LightBurn camera workflow |
| Autofocus measurement at a point | **Fair** | `/device/camera/measure_distance` exists; reachable via the bridge, or via an `M130`-style macro on the serial path |
| Dual-camera wall view | **Unknown** | Depends entirely on whether two streams exist |
| Smart Fill / batch auto-layout | **None** | On-machine feature, no third-party interface |
| Material recognition | **None** | Same |

## What to capture

If you have an Ultra:

1. Does the WeCreat preset in LightBurn 2.1 find the Ultra's camera at all?
2. What does `GET http://<ip>:8080/camera/take_photo` return — resolution, orientation, one image
   or a composite?
3. Does `GET /device/camera/download` return calibration, and what does its structure look like?
4. Is there any endpoint that yields a *second* camera?

→ Template: `captures/templates/rest-probe.md`

---

## LightBurn ships a built-in WeCreat camera preset — CONFIRMED-vendor

**2026-08-25.** LightBurn 2.1.04's *Camera Presets* dialog carries a **WeCreat** entry, listed
alongside Creality, Thunder Laser and xTool. Its description, verbatim:

> **WeCreat** — Network connection to WeCreat camera over USB

Three consequences for this project.

**You do not need to hand-configure the camera.** There is a vendor preset. Use it. Earlier drafts
of this repo treated the camera as something to be reached by URL discovery; that was the hard way
round.

**It confirms the architecture.** "Network connection … over USB" is precisely what
[docs/01](01-architecture.md) and [docs/05](05-connectivity.md) reconstructed from USB enumeration
and HTTP probing: the machine presents a **Linux RNDIS network gadget** over the single USB cable,
and the camera is an HTTP stream on that private network — not a UVC webcam. Creality and xTool
appear with the same wording because they use the same pattern. Our reverse-engineered finding and
the vendor tool's own UI agree, so this moves from `CONFIRMED-hardware` to **`CONFIRMED-vendor`**.

**It bears on the device-class question.** A first-class WeCreat presence inside LightBurn makes it
likely that WeCreat-specific behaviour — device detection, `Exit_Preview_Mode`, `M41Y1` — is driven
by LightBurn recognising the controller banner, not by any `GCodeFlavor` string we set. See
[the open question](../captures/stage4-which-device-are-we-testing.md).

### The preset's URL is the endpoint we reverse-engineered

Connecting LightBurn's built-in **WeCreat** preset fills in:

```
Camera Type : Network Camera
Mount Type  : Overhead Mounted
Network URL : http://192.168.42.1:8080/camera/take_photo
Status      : Connected
```

That URL is **character-for-character** the endpoint this project found by probing
([capture](../captures/stage2-rest-benchy.md), which recorded `GET /camera/take_photo` returning an
826,131-byte JPEG from `192.168.42.1:8080`).

Host, port and path, arrived at independently:

| | Our method | LightBurn's preset |
|---|---|---|
| Host | inferred from the RNDIS adapter at `192.168.42.100/24` | `192.168.42.1` |
| Port | port scan | `8080` |
| Path | endpoint enumeration | `/camera/take_photo` |

It also settles the stream question: it is a **snapshot** endpoint, not MJPEG. LightBurn's *New
Camera* dialog offers "snapshot images or MJPEG stream" and the WeCreat preset takes the snapshot
path.

**Grade: `CONFIRMED-vendor`.** Both the architecture and the endpoint map.

### Practical status of the camera in LightBurn

| Item | State |
|---|---|
| Connection | ✅ Connected via the built-in preset — no manual URL needed |
| Live preview | ✅ Working |
| Image orientation | ⚠️ Arrives **rotated ~90°**, as previously captured |
| Lens Calibration | ❌ **Uncalibrated** |
| Workspace Alignment | ❌ **No Alignment** |

So the camera *works* but is not yet *useful for placement*. Two jobs remain, both standard
LightBurn procedures rather than anything WeCreat-specific:

1. **Calibrate Lens** — LightBurn's dot-pattern routine, which also absorbs the rotation
2. **Align to Workspace** — maps the image onto the 210 × 210 field

Both are deferred past v1.0 ([ROADMAP](../ROADMAP.md)), but the starting point is much better than
the repo previously assumed: there is a working vendor preset, not a URL hunt.
