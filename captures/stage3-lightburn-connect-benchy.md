# Stage 3 — LightBurn connects — and tells us the profile is wrong

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04** · **COM7**
**Contributor:** Lee Gillie

## What happened

```
Waiting for connection...
ok
[WeCreat Lumos :ver 000240]
Your laser has been detected as a WeCreat device but you are not using a custom
gcode device with the WeCreat device flavor. The device may not work correctly
as a result.
ok
```

**Two results, one good and one important.**

## 1. It connects

The draft profile talks to the machine. The banner arrives, `ok` handshaking works, LightBurn
2.1.04 handles WeCreat's extra `ok` responses without desyncing. The GRBL-over-serial architecture
is validated end to end.

## 2. LightBurn has a native WeCreat device flavor — and we should be using it

**LightBurn detects WeCreat machines by their banner and expects a specific device
configuration**: a **Custom GCode** device with the **GCode Flavor** set to **WeCreat**.

Our draft profiles declare `"Name": "GRBL"` — modelled on WeCreat's own
`WeCreat-Lumos-v1.5.lbdev`. That file dates from **August 2025**, which predates LightBurn's
WeCreat flavor. **So the vendor's own published profile is now outdated too**, and anyone using it
gets the same warning.

LightBurn's Custom GCode documentation confirms WeCreat-specific handling, noting *"Disable for
WeCreat devices"* against two settings:

- **Supports G53 Command** → disable
- **Fetch configuration on connect** → disable

That second one neatly explains [Stage 1](stage1-serial-benchy.md): `$$`, `$#` and `$G` are stubs
on this firmware, so a client that tries to fetch configuration on connect gets nothing useful.
LightBurn already knows this and has a switch for it.

## Consequences

| | |
|---|---|
| Our six draft profiles are the **wrong device class** | They connect, but LightBurn warns they "may not work correctly" |
| WeCreat's own Lumos profile is **also outdated** | Same warning applies. Another reason not to use it on an Ultra — on top of its 116 × 116 mm workspace |
| The fix is a **profile regeneration**, not a redesign | Same workspace, origin, baud and checklist; different device type and a handful of flavor settings |
| We need the **exact JSON keys** | LightBurn writes them; the reliable way to learn them is to build the device in the wizard and export it |

## Next

Build the device natively in LightBurn's wizard, export it, and regenerate
`tools/profile-spec.json` and `tools/build-profiles.ps1` from the real key names rather than
guessing at them.

**This is a good outcome.** A native WeCreat device flavor means LightBurn already accommodates
this machine family's quirks — the extra `ok`s, the missing configuration query — and we get that
handling for free instead of working around it.
