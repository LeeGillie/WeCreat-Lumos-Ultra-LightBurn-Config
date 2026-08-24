# Stage 2 — Controller HTTP API — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY · **Controller:** `192.168.42.1` · **Contributor:** Lee Gillie

Raw capture: [`stage2-rest-benchy-20260824-092641.txt`](stage2-rest-benchy-20260824-092641.txt)

> Read-only throughout. `/test/cmd/mcu` was deliberately not called — it executes G-code and
> bypasses the lid interlock. The head-moving autofocus probe was skipped.

## Ports on the controller

| Port | Service | State |
|---|---|---|
| 22 | SSH | **OPEN** |
| 80 | HTTP | closed |
| **8080** | **REST control API** | **OPEN** |
| **8082** | **unauthenticated file listing** | **OPEN** |
| 8888 | — | closed |

**The `weburn` endpoint map, reverse-engineered on a Vision 20 W, survives into the Lumos Ultra.**
That is the headline: a bridge of that kind is viable on this machine.

## Endpoint results

### `GET /camera/take_photo` — HTTP 200, **826,131 bytes JPEG**

The camera works over HTTP and returns a full-size still. The probe failed to save it to a file
this run (no `Content-Type` header, so the image sniffing missed and the JPEG was dumped into the
log as mojibake) — **fixed**, the probe now sniffs the JPEG magic bytes and writes the image to
`captures/`. Re-run to collect the actual photo.

### `GET /device/camera/download` — HTTP 200, 296 bytes

```json
{"bottomData":{"points":[{"x":869,"y":1892},{"x":100,"y":100},{"x":2262,"y":1901},
                         {"x":100,"y":100},{"x":100,"y":100},{"x":100,"y":100},
                         {"x":865,"y":3280},{"x":100,"y":100},{"x":2256,"y":3289}]},
 "customThickness":0,
 "basicData":{"x":20,"y":20,"width":170,"height":170,"type":"5W","id":"lumosPro"}}
```

Three things to note, with care about how much weight they carry:

1. **`"id":"lumosPro"`, `"type":"5W"`.** The controller's internal identifiers match neither the
   marketing name nor the `$I` string (`WeCreat Lumos`). There is no publicly known "Lumos Pro"
   product, and "5W" matches no Ultra source (the Ultra is 6 W UV + 60/100 W MOPA).
   **INFERRED: these are firmware defaults from a shared/related product profile**, not a
   description of this machine. Do not treat them as model identification.
2. **`"width":170,"height":170` at origin `(20,20)`.** This is *camera calibration* geometry, not
   necessarily the laser field. It does not match the Ultra's published 210 × 210 mm. It may be
   the calibration target region, or it may be another shared default. **UNKNOWN — do not use
   this as a field size.** Stage 4 measurement remains the authority.
3. **The calibration is largely unpopulated.** Of nine grid points, five are the placeholder
   `{"x":100,"y":100}`. Only four corners carry real values. This camera has not been fully
   calibrated on this machine, which is further reason to treat `basicData` as default data.

### `POST /process/status` — HTTP 200

```json
{ "code" : 0, "result" : "ok", "status" : 5 }
```

**The response shape has changed from the Vision generation.** `weburn` documented
`{"code":0,"status":"","result":0}` — `status` was a number and `result` a number; here `result`
is the string `"ok"` and `status` is `5`. `weburn`'s state machine reads `status` 2 or 3 as
running; **`5` is a value it never saw**, and its meaning is unknown. Presumably an idle or ready
state, since the machine was idle. **UNKNOWN.**

## What this changes

| Question | Before | Now |
|---|---|---|
| Is the REST API on :8080 unchanged on the Ultra? | Unknown | **Present and answering.** Endpoint paths survive; at least one response shape has changed |
| Is a `weburn`-style bridge viable? | Speculative | **Yes in principle** — camera, status and (untested) bulk upload are all reachable |
| Can we get camera stills without LightBurn? | Unknown | **Yes** — one HTTP GET |
| Is the machine network-exposed? | Assumed | **Confirmed** — SSH and an unauthenticated filesystem listing, both open |

## Security note

SSH and an open, unauthenticated file listing are both live on this controller, exactly as found
on the Vision generation. This is a private USB-only subnet (`192.168.42.0/24`), which limits
exposure — but **do not put a WeCreat machine on a routable network and do not port-forward it**.
See [SAFETY.md](../SAFETY.md#network-exposure).

## Next

**Stage 2b — map port 8082.** An unauthenticated filesystem listing is the most promising
remaining read-only lead: machine definitions and configuration live on that SBC, and they are
the only plausible source for the things the serial interface will not tell us — the real field
size, the UV/MOPA source-select command, and any MOPA pulse-width parameter.

Also worth re-running Stage 2 to collect the camera JPEG now that saving is fixed. The open
question it answers: **how many cameras does the Ultra actually have** — one frame, or a
composite of two?
