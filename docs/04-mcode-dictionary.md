# 04 — WeCreat M-code / G-code Dictionary

WeCreat's controllers speak a **private M-code dialect** layered on a GRBL-ish G-code stream.
There is no vendor documentation for it. This table is the most complete public compilation we
know of, assembled from WeCreat's own shipped `.lbdev` profiles, their support articles, the
`weburn` reverse-engineering project, and owner reports.

> ## ⚠️ The single most important rule
>
> **WeCreat renumbers M-codes between machine models.** `M14` is in every Vision-family start
> block and absent from the Lumos. `M18` exists only on the Lumos. `M16`/`M17` mean "Umode" on
> the Vision but AlgoLaser uses the same numbers for an air pump.
>
> **No Lumos M-code may be assumed valid on a Lumos Ultra.** Do not paste the Lumos start block
> into an Ultra profile. This is why `profiles/draft/` ships with **empty** start G-code.

---

## Dictionary

| Code | Params | Meaning | Grade | Seen on |
|---|---|---|---|---|
| `M1` | `S0` / `S1` | Job content-type selector. `S0` labelled **"BMP"** (raster), `S1` labelled **"svg"** (vector). Likely tells the planner whether to expect image-raster or vector geometry. Standard `M1` = optional stop — **repurposed** | Labels CONFIRMED-vendor; meaning INFERRED | Lumos |
| `M2` | — | End of program. Treated by `weburn` as terminator of a bulk upload | CONFIRMED-community | Vision |
| `M6` | — | **Job end.** Used as `EndGCode`. Standard `M6` = tool change — **repurposed** | CONFIRMED-vendor | Vision, Vision Pro, Vista |
| `M14` | `S0` / `S1` | **Laser-module fan** off / on | CONFIRMED-community | Vision, Vision Pro, Vista — **not** Lumos |
| `M15` | `S0` / `S1` | **Exhaust fan** off / on | CONFIRMED-community | All models |
| `M16` | — | **"Enable Umode"** — meaning unknown, see below | Label CONFIRMED-vendor; function UNKNOWN | All models |
| `M17` | — | **"DisEnable Umode"** (sic) — inverse of `M16` | Label CONFIRMED-vendor; function UNKNOWN | All models |
| `M18` | `S0` / `S1` | **Laser source select.** `S0` labelled **"1064red"** (IR), `S1` labelled **"455Blue"** (blue diode) | Labels CONFIRMED-vendor; effect **never publicly verified** | Lumos only |
| `M19` | `S0` | Present in the Lumos start block, unlabelled | UNKNOWN | Lumos |
| `M21` | `S0` / `S1` | **Red dot / pointer** off / on | CONFIRMED-community | Vision family |
| `M27` | — | **Position report.** `weburn` parses a reply shaped `M27 X…,Y…,Z…` and synthesises a GRBL status frame from it | INFERRED (strong — code parses the exact shape) | Vision |
| `M57` | `A<n> B<n>` | Lumos start block, `A130 B120`. **Unknown.** Not the field size — the Lumos field is 116 × 116 mm | UNKNOWN | Lumos |
| `M107` | `X<n> Y<n>` | Lumos start block, `X-60 Y-60`. Best guess: **workspace / field origin offset** — a 116 mm field centred on the optical axis has corners near ±58 mm. Standard `M107` = fan off — **repurposed** | INFERRED | Lumos |
| `M130` | `X<mm> Y<mm>` | **Autofocus at bed coordinate.** The best-attested WeCreat code — three independent sources. Set as LightBurn's *Focus Z* command or bound to a macro. Standard `M130` = set PID P — **repurposed** | CONFIRMED-community | Vision family |
| `G0 Z<neg>` | | Move to absolute focus height. Z is **negative-down** in machine coordinates (`G0Z-84` ≈ 16 mm object height) | CONFIRMED-community | Vision |
| `?` | — | GRBL realtime status query | CONFIRMED-community | All |
| `!` | — | Feed hold / pause | CONFIRMED-community | All |
| `~` | — | Cycle start / resume | CONFIRMED-community | All |
| `0x18` | — | Soft reset (Ctrl-X) | CONFIRMED-community | All |

### GRBL `$` command support — measured on a Lumos Ultra, 2026-08-24

**CONFIRMED-hardware** ([capture](../captures/stage1-serial-benchy.md)). The controller
implements enough GRBL to stream jobs and report status, and **not** the settings subsystem.

| Command | Result | Implemented? |
|---|---|---|
| `?` | `<Idle\|MPos:0.000,0.000,0.000\|FS:0,0\|Pn:Z\|WCO:0.000,0.000,0.000>` | **Yes** — full GRBL 1.1 status report, three axes |
| `$I` | `[WeCreat Lumos :ver 000240]` | **Yes** |
| `$$` | bare `ok`, nothing else | **No** |
| `$#` | bare `ok` | **No** |
| `$G` | bare `ok` | **No** |

**The practical consequence: you cannot read the field size out of the machine.** `$130`/`$131`
(max travel), `$110`/`$111` (max rates) and `$30` (spindle/S max) do not exist here. Field size
and scaling must be established by measurement — see [03-bringup-plan.md](03-bringup-plan.md)
Stage 4.

### The identity string does not name the model

`$I` returns **`[WeCreat Lumos :ver 000240]`** on a **Lumos Ultra**. It does not say "Ultra".
A Lumos (non-Ultra) reported `[WeCreat Lumos :ver 000207]` in a public forum capture — same
product string, same format, older build. Firmware appears to be shared across the family.

> ⚠️ **Trap.** WeCreat's official `WeCreat-Lumos-v1.5.lbdev` will connect to an Ultra without
> complaint, because nothing in the handshake distinguishes them. That profile declares a
> **116 × 116 mm** workspace; the Ultra's field is **210 × 210 mm**. Jobs would be silently
> mis-scaled and mis-placed, with no error.

### Baud rate

**1,000,000 baud confirmed working** on the Ultra, matching the vendor Lumos profile.

## Corrections to claims circulating elsewhere

- **`M14` is not a "passthrough/bulk mode" switch.** `M14S0`/`M14S1` are laser-module fan off/on.
  The passthrough↔bulk switch lives entirely inside the `weburn` bridge program, which watches
  the serial stream for the literal string `M14S0` that the user manually inserts into
  LightBurn's start script. It is a property of the bridge, not of the firmware.
- **There is no `M13`.** A placeholder string in `weburn`'s source reads `M13X_Y_`, but the byte
  array on the same line decodes to `M130X200Y150`. It is a typo.
- **Do not import AlgoLaser's `M16`/`M17` semantics.** AlgoLaser genuinely uses those numbers for
  an air pump. WeCreat's own label says "Umode", and WeCreat has separate fan codes. The
  collision is coincidental.

---

## Reconstructed start / end blocks (vendor, verbatim)

```
Vision / Vision Pro / Vista
  StartGCode:  M14S1        ; laser-module fan on
               M15S1        ; exhaust fan on
               M16          ; "Enable Umode"
  EndGCode:    M6           ; job end

Lumos                       (note: no M14, no EndGCode)
  StartGCode:  M15S1        ; exhaust fan on
               M16          ; "Enable Umode"
               M57A130B120  ; UNKNOWN
               M107X-60Y-60 ; field origin offset (inferred)
               M19S0        ; UNKNOWN
  Macros:      M18S1 "455Blue"   M18S0 "1064red"
               M1S1  "svg"       M1S0  "BMP"

Lumos Ultra                 UNKNOWN — this is what the project exists to determine
```

---

## What is "U mode"?

`M16` / `M17` appear in the start block of **every** WeCreat profile, so they are fundamental —
and nobody knows what they do. Hypotheses, with the evidence for and against:

| Hypothesis | Verdict | Reasoning |
|---|---|---|
| A 4th / rotary "U axis" | **Near-refuted** | WeCreat's own rotary guide tells LightBurn users to "Set Axis to **A**". A rotary enable in the unconditional start block of every machine would also be wrong |
| **"USB mode"** — hand MCU control from the SBC front-end to the USB serial stream | **Best fit, unproven** | Explains why it is in every start block, why an inverse exists, and why the architecture needs it (the SBC normally owns the MCU via `/test/cmd/mcu`) |
| "User mode" / unlocked mode | Plausible, unproven | "DisEnable" reads like a literal translation; 用户模式 is a natural candidate |
| Units mode | **Unlikely** | Units are `G20`/`G21`, and LightBurn has its own modal fields |
| Air assist | **Unlikely** | That's AlgoLaser. WeCreat labels it "Umode" and has separate fan codes |

**Decisive tests:** a firmware string dump, or an owner sending `M17` alone and reporting what
stops working. Do the firmware one first — it is free and cannot damage anything.

---

## How to add a code to this table

1. Get evidence. A vendor label, a support article, a `weburn` constant, or your own
   differential capture (see [03-bringup-plan.md](03-bringup-plan.md) Stage 5).
2. Open a **M-code discovery** issue with the raw capture attached.
3. Grade it honestly. `INFERRED` is a perfectly respectable entry; a wrong `CONFIRMED` is not.
4. Note which model it was seen on. Model-scoped, always.

**We will not accept an entry whose evidence is "I sent it and nothing bad happened."** Absence
of an observed effect is not a meaning.
