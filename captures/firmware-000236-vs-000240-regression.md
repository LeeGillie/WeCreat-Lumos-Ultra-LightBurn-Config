# Firmware `000236` works; `000240` is the one that drifts — a likely regression

**Date:** 2026-08-28 · **Grade:** CONFIRMED-community (the version strings) · INFERRED (the
regression) · **Contributor:** Jon C (`goeland86`), LightBurn Dev Team

## The exchange

This project asked LightBurn's dev team what firmware their Lumos Ultra reports, on the assumption
that their drift-free result came from a **newer**, unreleased build. He had said as much himself —
that he would not be surprised if LightBurn had been sent in-flight firmware.

The answer went the other way:

> *"Interesting - looks like they have a regression."*
>
> *"Our machine reads `WeCreat Lumos :ver 000236` in the console."*

| Machine | Firmware | Dense fills |
|---|---|---|
| LightBurn dev team's Lumos Ultra | **`ver 000236`** | complete, no drift |
| This project's Lumos Ultra | **`ver 000240`** | stall and drift |

**The working machine is on the older firmware.** Four increments older.

## Why this matters more than anything else found this week

Every explanation on the table until now put the fault somewhere structural — the status report,
the buffer mismatch, `G91` amplification, the streaming architecture itself. All of those are real
and all of them are documented here. But they are all properties of a *design*, and a design does
not change between two units of the same model.

**A version number does.** If `000236` runs the same class of job cleanly on the same model with
the same software, then something changed between `000236` and `000240` that made it worse — and
that is a defect with a range to bisect rather than an architecture to redesign.

It also explains, without special pleading, why the two clean results reported to this project both
came from machines that are not this one.

## ⚡ The speed question — answered, and it points the wrong way for buffer starvation

The obvious objection to Jon's clean result was that a **slow** job never empties the buffer and so
completes regardless of firmware — the same confound that limits the
[Flex result](community-01-lumos-flex-chris-zambesi.md). Asked, and answered:

> *"I was setting my machine to run in mm/s since it's a galvo, and I was sending it values between
> 1500 and 2000mm/s on the UV laser. 12000mm/min translates to 200mm/s… So something seems to be
> bizarre."*

| | Speed | = mm/min | Source | Result |
|---|---|---|---|---|
| LightBurn dev team, `000236` | **1500–2000 mm/s** | 90,000–120,000 | UV | **clean** |
| This project, `000240` | **200 mm/s** | 12,000 | 100 W MOPA | **stalls, drifts** |

**Jon was running 7.5–10× faster than the jobs that fail here, and had no trouble.**

That is backwards for a starvation model. Buffer starvation predicts failure at **high** feed rates,
where the machine consumes moves faster than the link delivers them — which is exactly why a
127-byte window on a galvo was described as *"running dry very quickly"*. Instead the fast machine
is fine and the slow one fails.

**The speed confound is therefore resolved, and in the direction that strengthens the firmware
hypothesis**, because the one remaining difference doing real work is the version number.

### For calibration — what MakeIt itself uses

Both figures are read from WeCreat's own generated jobs, so this is the vendor's own range:

| Job | Marking feed | = mm/s | Travel feed |
|---|---|---|---|
| Small MOPA job ([capture](stage5-jobgcode-mf-151-benchy-20260824-103612.txt)) | `G1F12000` | 200 | `G0F300000`–`F480000` |
| Deep emboss ([capture](makeit-cache-and-absolute-gcode.md)) | `G1F87000` | 1450 | `G0F300000` |

So **12,000 mm/min is a genuine MakeIt value**, not a mis-set unit — it is what the vendor uses for
that class of job. But MakeIt spans **12,000 to 87,000 mm/min** for marking, and this project has
only ever tested at the bottom of that range. Jon's 1500–2000 mm/s sits at the top, next to the
emboss figure.

**Worth testing here: the same fill at 87,000 mm/min.** If drift is worse at high speed, starvation
survives after all. If it is better or unchanged, starvation is in serious trouble as an
explanation and firmware is left holding the field. Either result is decisive, and it costs one run.

## What this still does NOT establish

**One difference remains unaccounted for: the source.** Jon ran **UV**; the failing jobs here are
**100 W MOPA**. Fill type on his side is also still unstated.

So the honest statement is: **two machines of the same model, on different firmware, at speeds that
should have favoured the failing one, produced opposite outcomes.** "Regression" is Jon's reading
and now a considerably better-supported one — but it is not proven, and this project cannot prove
it alone. There is no public firmware archive, so downgrading `000240` to `000236` and re-testing is
not something an owner can do.

**WeCreat can settle it in minutes.** They have both builds and the changelog between them.

## The bisect this opens up, and it needs owners

The question is no longer "is this machine broken". It is **which firmware versions are affected**.
That is answerable by the community, and cheaply — every Ultra owner has one data point.

What a usable report needs:

| | |
|---|---|
| **Firmware version** | the `[WeCreat Lumos :ver ######]` string on connect |
| **Does a dense fill complete?** | yes / stalls |
| **Speed** | the failing case here is 12000 mm/min |
| **Fill type** | plain `Fill` or `Offset Fill` |
| **Source** | UV, fiber, MOPA, diode |

Without the last three, a "works fine for me" cannot be interpreted — which is exactly what the
Flex result demonstrated.

## Status of the three reports so far

| Machine | Firmware | Source / speed | Result |
|---|---|---|---|
| This project's Ultra | `000240` | 100 W MOPA @ 12,000 mm/min (200 mm/s) | **stalls, drifts** |
| LightBurn dev team's Ultra | **`000236`** | UV @ 90,000–120,000 mm/min (1500–2000 mm/s) | clean |
| Chris Zambesi's Lumos Flex | not reported | diode, speed not stated | clean |

## Actions

1. **Report the version pair to WeCreat.** This is public forum information, so there is no
   confidentiality issue, and it gives them a specific range to look at rather than a symptom.
2. **Ask owners for version strings** alongside their results — the owners' group post now does.
3. ~~**Ask Jon for source, speed and fill type.**~~ **Answered 2026-08-28** for source and speed —
   UV at 1500–2000 mm/s. Fill type still unstated.
4. **Run the same fill at 87,000 mm/min here.** One run, and it either rescues the starvation model
   or finishes it off.
5. **Ask WeCreat whether `000236` is obtainable**, and whether downgrading is supported. If it is,
   this becomes a controlled single-variable test on one machine — the cleanest possible evidence.
