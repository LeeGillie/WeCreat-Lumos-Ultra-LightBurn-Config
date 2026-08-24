# Stage 0 — USB enumeration

> **No beam. No software. About two minutes.**
> This is the single most valuable test in the project — it settles whether the Lumos Ultra is a
> GRBL serial device or a real galvo controller, which everything else depends on.

## My setup

- Machine: Lumos Ultra
- Sources fitted: ☐ 6 W UV  ☐ 60 W MOPA  ☐ 100 W MOPA
- Lens installed during test:
- Accessories fitted:
- OS + version:
- MakeIt version:
- LightBurn version:
- Machine firmware version (if known):

## What I ran

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1
```

(Linux: `lsusb`, `lsusb -v -d <vid:pid>`, `dmesg | tail -60`, `ls -l /dev/serial/by-id/`, `ip -br a`)

## Output — paste raw, do not retype

```
<paste here>
```

## The key lines

- COM port(s) that appeared when the machine was powered on:
- Their hardware IDs (`VID_xxxx&PID_xxxx`):
- RNDIS / USB Ethernet adapter present? ☐ yes ☐ no — hardware ID:
- Network adapter address / subnet the RNDIS link came up on:
- Any device that appeared with **no** driver:

## Interpretation

Tick what matches:

- ☐ `VID_0525&PID_A4A2` or `VID_1D6B&PID_0104` → Linux USB gadget, same architecture as the Lumos. **Expected.**
- ☐ A COM port alongside it → the serial path exists, proceed to Stage 1
- ☐ COM port but no RNDIS → simpler than expected, REST path may be gone
- ☐ **`VID_9588` (BJJCZ/JCZ), or a WinUSB device with no COM port → the Ultra is a real galvo controller.** Say so loudly in the issue title — this would be excellent news and changes the project's whole architecture
- ☐ Two COM ports appeared (known WeCreat quirk — only one is functional)
- ☐ Something else entirely:

## Notes

<anything surprising>
