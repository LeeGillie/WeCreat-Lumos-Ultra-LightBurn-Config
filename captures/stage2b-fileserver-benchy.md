# Stage 2b — Controller filesystem — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY · **Controller:** `192.168.42.1:8082` · **Contributor:** Lee Gillie

> Read-only: HTTP GET only. Nothing written to the machine, no commands sent.
>
> **The raw dump is deliberately NOT committed.** It contains the device serial number and MAC
> address. `captures/fileserver-*/` is gitignored. Findings are curated here instead.

## The model question is settled

```
/etc/mbtc/devicename.txt   ->   Lumos Ultra
```

**CONFIRMED-vendor.** The machine's own configuration names it `Lumos Ultra`. The `$I` serial
identity string (`[WeCreat Lumos :ver 000240]`) is therefore a **family string, not the model** —
exactly as suspected in [Stage 1](stage1-serial-benchy.md), and now proven rather than inferred.

The trap stands and is now fully evidenced: nothing on the *serial* interface distinguishes an
Ultra from a Lumos, so WeCreat's 116 × 116 mm Lumos profile will attach to a 210 × 210 mm Ultra
without complaint.

## The controller hardware

| Fact | Value |
|---|---|
| SoC | **Allwinner R528** (`allwinner,r528`, family `sun8iw20`) |
| Manufacturer | `allwinnertech`, `DEVICE_PRODUCT='v3.5'`, `DEVICE_REVISION='v1.0'` |
| OS | **OpenWrt** — `/etc/uci-defaults/`, `/etc/rc.d/`, `/overlay/`, `sysupgrade.conf`, `opkg` |
| Vendor namespace | **`/etc/mbtc/`** (22 entries) |
| Camera device | **`/dev/video0`** — a single node |
| Also present | `dropbear` (SSH), `avahi`, `vsftpd` (FTP), Bluetooth stack |

An Allwinner R528 running OpenWrt is a full Linux SBC, which is consistent with everything
observed so far: `.tar.gz` firmware, an HTTP API, and a separate MCU doing the motion.

## Where the machine keeps its jobs — the important find

`/etc/mbtc/print.json`:

```json
{
    "framing_file": "/mnt/SDCARD/framing/framing_data.gcode",
    "print_file":   "/mnt/SDCARD/curve/print_data.gcode"
}
```

`/etc/mbtc/cfgs.json`:

```json
{ "savepath_gcode":"/mnt/UDISK/", "savepath_img":"/mnt/UDISK/",
  "debug_mode":"1", "videoid":"/dev/video0" }
```

**After MakeIt sends a job, the complete G-code for that job is sitting on the device and can be
read over HTTP.** That is a direct route to the entire M-code dictionary — source select, pulse
width, focus, rotary — with no Wireshark, no bridge, and without sending a single unknown command
to the machine. See `tools/stage5-jobfile-grab.ps1`.

Note also `"debug_mode":"1"` — the controller ships in debug mode.

## New M-codes, previously unknown anywhere

`/etc/mbtc/inverse_distance.json`:

```json
{
    "flag": 0,
    "0": { "inverse_dis": "M101X0.001\n",                "inverse_cmd": "M104X1" },
    "1": { "inverse_dis": "M44K0.00003273B0.02181818\n", "inverse_cmd": "M104X2" }
}
```

**`M44`, `M101` and `M104` appear in no WeCreat `.lbdev`, and in no prior reverse-engineering.**

| Code | Observed form | Reading | Grade |
|---|---|---|---|
| `M104` | `M104X1`, `M104X2` | Selects between **two configurations**, indices 1 and 2. The Ultra has exactly two optical paths (UV and MOPA). A **source- or lens-select** candidate | **INFERRED — do not send** |
| `M44` | `M44K0.00003273B0.02181818` | `K` and `B` read as the slope and intercept of a linear fit — a distance calibration | INFERRED |
| `M101` | `M101X0.001` | A scalar distance parameter, paired with `M104X1` | UNKNOWN |

`M104` is the most interesting lead in the project right now, and the correct way to confirm it is
**not** to send it — it is to run one job per source in MakeIt and diff the captured G-code.

## Other configuration of note

- **`/etc/mbtc/focus_light_cfg.json`** lists **two** focus lights: `focus_light_short` and
  `focus_light_long`, both `on`. Two aiming/focus emitters, not one.
- **`/etc/mbtc/pwm_multi.json`** defines PWM channels `frontlight` (chip 0, ch 5), `backlight`
  (chip 0, ch 7) and `servo` (chip 1, ch 0, **disabled**). An unused servo channel is worth noting
  given the accessory ecosystem.
- **`/etc/mbtc/materialinfo.json`** holds a `vistaThicknessData` curve mapping a camera measurement
  (~2042–2164) to a thickness (−18 … +12 mm). The `vista` naming is inherited from an earlier
  product — more evidence that WeCreat shares firmware across models.
- **`/etc/mbtc/camera_factory.json`** carries `"id":"lumosUltra"` — while the *user* calibration in
  `camera.json` carries `"id":"lumosPro"`. The factory file is right; the user file appears to have
  been overwritten with a default from another product. This resolves the ambiguity flagged in
  [Stage 2](stage2-rest-benchy.md), and is a good reason to trust `camera.json` less.
- Both camera files agree on `"type":"5W"` and `"x":20,"y":20,"width":170,"height":170`. Since the
  factory file uses these too, they are **the Ultra's real factory camera-calibration values** —
  but they describe the *camera* region, not the laser field. Still **not** a field size.

## Security

An unauthenticated HTTP listing of the entire root filesystem, plus SSH and FTP daemons, on a
device with `debug_mode` enabled. On the USB-private `192.168.42.0/24` subnet this is contained.
**Do not put this machine on a routable network.** See [SAFETY.md](../SAFETY.md#network-exposure).

## Next

1. Run a small job in MakeIt, then `tools/stage5-jobfile-grab.ps1` — the M-code table.
2. Repeat changing one variable (UV → MOPA) and diff. That confirms or kills the `M104` reading.
