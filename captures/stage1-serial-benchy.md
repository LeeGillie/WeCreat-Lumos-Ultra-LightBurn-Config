# Stage 1 — Serial identity — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY · **Port:** COM7 @ **1,000,000 baud** · **Contributor:** Lee Gillie

Raw capture: [`stage1-serial-benchy-20260824-092231.txt`](stage1-serial-benchy-20260824-092231.txt)

> **First published serial-level characterisation of a Lumos-family WeCreat controller.**
> Read-only throughout: no beam, no motion, no M-codes.

## Result

```
--- ?    (GRBL realtime status query) ---
  <Idle|MPos:0.000,0.000,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
  ok

--- $$   (settings dump) ---
  ok                          <- nothing else. Not implemented.

--- $I   (build info) ---
  [WeCreat Lumos :ver 000240]
  ok

--- $#   (work coordinate offsets) ---
  ok                          <- not implemented

--- $G   (parser state) ---
  ok                          <- not implemented
```

No unsolicited banner on port open — it is emitted on power-up/reset only. `$I` retrieves it on
demand.

## Findings

| # | Finding | Grade |
|---|---|---|
| 1 | **1,000,000 baud is correct**, first try — matching the vendor Lumos profile | CONFIRMED-hardware |
| 2 | **`?` returns a full GRBL 1.1 status report.** Three axes, standard field layout | CONFIRMED-hardware |
| 3 | **`$$` is NOT implemented** — the controller acknowledges it and returns nothing | CONFIRMED-hardware |
| 4 | **`$#` and `$G` are NOT implemented** — bare `ok` | CONFIRMED-hardware |
| 5 | **`$I` IS implemented** and returns the identity string | CONFIRMED-hardware |
| 6 | **The identity string is `[WeCreat Lumos :ver 000240]` — it does not say "Ultra"** | CONFIRMED-hardware |
| 7 | **`Pn:Z` — the Z limit/probe pin reads as triggered at rest** | CONFIRMED-hardware |

## Why these matter

### `$$` being a stub closes off the easy route to field size

The hope was that `$130`/`$131` would give the real working area, `$110`/`$111` the max rates,
and `$30` the S-value scale, straight from the controller. **They are not available.** WeCreat
implemented enough GRBL to stream jobs and report status, but not the settings subsystem.

Consequence: **field size and scaling must be established by measurement** — Stage 4 framing with
calipers — not read from the machine. `S_Scale: 1000` in our profiles remains inherited from the
vendor Lumos profile and unverified.

### The machine identifies itself as "Lumos", not "Lumos Ultra"

This is the most consequential finding, and it is a **trap for users**:

- LightBurn cannot distinguish an Ultra from a Lumos by its identity string.
- Firmware appears to be shared across the Lumos family — the Lumos (non-Ultra) reported
  `[WeCreat Lumos :ver 000207]` in a public forum capture; this machine reports `ver 000240`,
  same format, same product string, newer build.
- **Therefore WeCreat's official `WeCreat-Lumos-v1.5.lbdev` will appear to work on an Ultra** —
  it will connect, and it will be accepted. But that profile declares a **116 × 116 mm**
  workspace, and the Ultra's field is **210 × 210 mm**. Jobs would be silently mis-scaled and
  mis-placed with no error and no warning.

This alone justifies the project: the "just use the Lumos profile" workaround an Ultra owner
would naturally reach for is actively wrong, in a way that produces no error message.

### `Pn:Z`

In GRBL's status report, `Pn:` lists **currently triggered input pins**. `Pn:Z` means the Z
limit (or probe) input is asserted while the machine sits idle. Most likely the focus carriage
rests against its top limit. Worth knowing before enabling Z or attempting homing — our draft
profiles ship with `EnableZ: false` and `HomeOnStartup: false`, which remains the right default.

## Open questions this raises

1. Does `$I`'s version number track the machine model at all, or only the firmware build?
2. Is there any command that *does* report the field size? (Nothing in the `$` set.)
3. Does `Pn:Z` clear when the focus axis moves off its limit, or is it stuck asserted?
4. What is the Ultra's actual field size, measured? → **Stage 4**

## Next

Stage 2 — the controller's HTTP API at `192.168.42.1`. That is where the camera, autofocus and
bulk job upload live, and it is the only remaining read-only stage.
