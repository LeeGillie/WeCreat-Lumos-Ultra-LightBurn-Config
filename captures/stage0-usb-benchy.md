# Stage 0 — USB enumeration — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY (Windows 11 Pro) · **Contributor:** Lee Gillie

Raw capture: [`stage0-usb-benchy-20260824-064202.txt`](stage0-usb-benchy-20260824-064202.txt)

> **This is the first published hardware confirmation of the Lumos Ultra's controller
> architecture.** It settles the question the whole project was built around.

## Setup

- Machine: WeCreat Lumos Ultra
- Sources fitted: 6 W UV + 100 W MOPA
- Accessories fitted: none for this test
- OS: Windows 11 Pro (10.0.26200)
- MakeIt version: 3.0.6
- LightBurn version: 2.1.04
- Machine firmware version: not yet read — Stage 1
- Connection: single USB cable, direct to PC

## Result

```
=== 4. Serial ports present right now ===
  USB-SERIAL CH340 (COM7)
      HWID: USB\VID_1A86&PID_7523\A&336F6178&0&2

=== 5. RNDIS / USB-Ethernet gadgets ===
  USB Ethernet/RNDIS Gadget
      HWID: USB\VID_0525&PID_A4A2\A&336F6178&0&3

=== 7. Network adapters (extract) ===
  Ethernet 7    USB Ethernet/RNDIS Gadget    Up    1.1 Gbps
  Ethernet 7    192.168.42.100/24
```

Nothing resembling a galvo controller appeared anywhere in the full VID/PID list — no `VID_9588`
(BJJCZ/JCZ), no unrecognised WinUSB device, no driverless device.

## Interpretation

| Observation | Conclusion | Grade |
|---|---|---|
| `VID_1A86&PID_7523` — WCH CH340 USB-serial bridge, COM7 | The Ultra speaks **GRBL over a serial port**, exactly as the Lumos does | CONFIRMED-hardware |
| No BJJCZ / JCZ / EZCAD device present | LightBurn's **galvo device class is genuinely unavailable** — Q-Pulse Width, Frequency, lens correction, galvo rotary, Split Marking and 3D depth maps are all out | CONFIRMED-hardware |
| `VID_0525&PID_A4A2` — Linux USB Ethernet/RNDIS gadget | The Linux SBC front-end is present, matching WeCreat's own bundled driver INF exactly | CONFIRMED-hardware |
| CH340 is a **discrete** bridge, not a CDC-ACM interface on the gadget | The G-code stream reaches the **motion MCU directly**; the SBC is a separate USB device. Previously inference, now observed | CONFIRMED-hardware |
| Both devices share hub instance `A&336F6178` (ports 2 and 3) | One cable in, an internal hub, two independent devices behind it | CONFIRMED-hardware |
| RNDIS adapter up at `192.168.42.100/24` | The controller has a **private USB-only network**, and sits at (almost certainly) `192.168.42.1`. This is the Stage 2 target | CONFIRMED-hardware |

## What did NOT happen

No beam, no motion, no commands sent to the machine. This was a read-only enumeration of what
Windows sees on the USB bus.

## Consequences for the project

- The architecture documented in [`docs/01-architecture.md`](../docs/01-architecture.md) is
  **correct**, and the draft profiles' `"Name": "GRBL"` / `"Type": "Serial"` shape is right.
- [Open question #1](../docs/02-feature-inventory.md#open-questions) is closed.
- Stage 2 became immediately actionable — we know the controller's address range without needing
  a packet capture first.
- The hard walls in [`docs/09-k9-and-mopa-limits.md`](../docs/09-k9-and-mopa-limits.md) are real,
  not hypothetical. MOPA pulse-width control and K9 3D engraving are not reachable through
  LightBurn's UI on this machine.

## Next

Stage 1 — serial identity on **COM7**. The `$$` settings dump is the prize: no WeCreat machine's
`$$` output has ever been published, for any model.
