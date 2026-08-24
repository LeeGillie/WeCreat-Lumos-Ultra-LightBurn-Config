# 05 — Connectivity

## What WeCreat documents

| Path | Ultra spec sheet | For LightBurn specifically |
|---|---|---|
| USB | ✅ listed | ✅ — WeCreat's LightBurn article: **"Only USB connection is supported."** That article lists Vision 20 W/40 W, Vista 10 W and Vision Pro 45 W, and **predates the Ultra** |
| Wi-Fi | ✅ listed | ❌ no evidence. Wi-Fi is a MakeIt path |
| Ethernet | ❌ not documented for the Ultra | — |
| Bluetooth | ❌ not documented as a machine transport | Used by mobile MakeIt for provisioning onto Wi-Fi, not as a control link |

**Working assumption: LightBurn ↔ Ultra is USB.** Unverified for this model — [open question 1](02-feature-inventory.md#open-questions).

## What the USB cable actually carries

One cable, a composite Linux USB gadget, at least two interfaces:

1. **RNDIS network interface** — a virtual Ethernet link to the controller's Linux SBC. This is
   how LightBurn's WeCreat camera works (LightBurn 1.7.00: *"Initial WeCreat Vision camera
   support over RNDIS"*).
2. **A serial interface** — what LightBurn streams G-code over.

Hardware IDs bound by WeCreat's own bundled driver
(`MakeIt!/resource/driver/win/rndis/rndis11.inf`) — **CONFIRMED-vendor**:

```
USB\VID_0525&PID_a4a2          ; Linux / NetChip USB Ethernet (RNDIS) gadget
USB\VID_1d6b&PID_0104&MI_00    ; Linux Foundation multifunction composite gadget, interface 0
```

`1d6b:0104` is the generic Linux Foundation multifunction composite gadget. `MI_00` confirms a
multi-interface device. **The Ultra's own VID/PID has not been captured by anyone** — that is
Stage 0.

WeCreat's troubleshooting article for the current generation tells users to look in Device
Manager for **"USB Ethernet/RNDIS Gadget"** under Network adapters *and* **"USB-Serial CH 340
(COMx)"** under Ports. Whether the Ultra still uses a discrete CH340 or a CDC-ACM gadget on the
SBC is unknown, and it matters: it determines whether the serial endpoint is the MCU directly or
the Linux front-end.

### Driver installation

The RNDIS driver ships inside MakeIt!:

```
C:\Program Files\WeCreat\makeit-builder\resource\driver\win\rndis\
    RNDIS.inf   rndis11.inf   RNDIS.cat   rndis11.cat
    usb-driver-installer-x64.exe
    usb-driver-installer-x86.exe
```

### Baud rate

WeCreat's published profiles use:

| Model | BaudRate |
|---|---|
| Lumos | **1 000 000** |
| Vision / Vision Pro / Vista | 500 000 |

The Ultra is untested. Start at 1 000 000 (Lumos lineage), then try 921 600, 500 000, 230 400,
115 200. On a CDC-ACM gadget the baud is nominal and any value works.

### Known quirks

- **Two COM ports may appear.** Only one is a real serial link. LightBurn dev comment:
  *"Should only see 1 com port on Windows. The second isn't truly a com port for serial
  communication."*
- **"Port failed to open — already in use?"** almost always means **MakeIt is still running** and
  holding the port. Close it entirely.
- **Extra `ok` responses.** WeCreat firmware emits unsolicited `ok` lines around the connect
  banner. LightBurn 2.1.00 added *"Allow for extra ok's from WeCreat firmware"* and 2.1.02
  *"Reverted LightBurn GRBL Protocol to GRBL-ish"* plus a *"WeCreat device detection / messaging
  fix"*. **Use LightBurn 2.1.02 or newer.** Older builds desynchronise and produce the
  stuck-at-99 % / "laser busy" symptom.

---

## The REST API (secondary path)

Reverse-engineered on the **Vision 20 W** by the `weburn` project. Unverified on the Ultra —
Stage 2.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/camera/take_photo` | Single still (4032 × 3024 JPEG on the Vision) |
| `GET` | `/device/camera/download` | Camera calibration JSON — 3×3 point grids at three heights plus focal lengths |
| `GET` | `/device/camera/measure_distance?x=<mm>&y=<mm>` | **Autofocus probe.** Returns `{"distance": …, "height-z": …}`. Errors return 0 for both |
| `POST` | `/process/status` | `{"code":0,"status":"","result":0}`. `2` or `3` = running |
| `POST` | `/process/control?action=0` | Pause |
| `POST` | `/process/control?action=2` | Cancel and return to 0,0,0 |
| `POST` | `/test/cmd/mcu?md5=<MD5>` | ⚠️ **Execute one G-code command immediately — bypasses the lid interlock** |
| `POST` | `/process/upload?md5=<MD5>` | Bulk-upload an entire job |

**MD5 scheme:** MD5 over the exact request body bytes, sent as an **uppercase** hex digest in the
`md5` query parameter. A wrong checksum returns a `calc_sum` field and the command does not run.

**Other ports found on the Vision generation:** `22` (SSH, root password login permitted) and
`8082` (unauthenticated Mongoose directory listing of the whole filesystem, `/etc/shadow`
visible). See [SAFETY.md](../SAFETY.md#network-exposure). Treat the machine as hostile on a
network.

### Why the bridge path is interesting anyway

`/process/upload` hands the controller a complete job to run on its own. That sidesteps the
serial link's per-line acknowledgement entirely — which is where a G-code-streamed **fill** loses
most of the machine's 16,000 mm/s headline speed. If Stage 10's benchmark shows a large gap, a
bulk-upload bridge is the answer, not a better profile.

---

## Firmware

Distributed as a **`.tar.gz`**, emailed by support or attached to a support article, and
side-loaded through a hidden MakeIt console (`Ctrl+Shift+P` on the documented Force-OTA path).
A published Lumos example is `Lumos1.2.2+217+20031.tar.gz` (~2 MB).

A tarball is a Linux userland payload — further evidence for the SBC architecture, and the
cheapest possible route to a real M-code table: unpack it and run `strings | grep -E "^M[0-9]+"`.
**If you can obtain the Ultra's OTA file, that is arguably the highest-value single artifact for
this project.** No firmware source, and no GPL offer-of-source page, has been found anywhere on
WeCreat's site — which is worth noting given the controller demonstrably runs Linux.
