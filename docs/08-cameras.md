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
