# Firmware `000236` vs `000240` — not a regression: prototype vs production

**Date:** 2026-08-28, **substantially corrected 2026-08-31** · **Contributor:** Jon C
(`goeland86`), LightBurn Dev Team · **Correction source:** WeCreat support

> ## ⚠️ CORRECTED 2026-08-31 — "regression" was the wrong frame
>
> This document originally read *"`000236` works; `000240` is the one that drifts — a likely
> regression."* WeCreat has since explained what those two versions actually are, and it changes
> the meaning entirely:
>
> - **`000236` was never released.** WeCreat supplied LightBurn with an **early prototype
>   machine** in the first half of 2026. It still runs prototype firmware, which WeCreat no longer
>   provides externally.
> - **`000240` is the official production firmware** — the version shipped to Kickstarter backers,
>   and the baseline for all WeCreat testing and improvement going forward.
>
> So this is **not** a good release that regressed. It is a prototype behaving differently from the
> production build that superseded it, which is an ordinary thing for a prototype to do.
>
> **Two consequences:**
>
> 1. **The downgrade test is off the table.** `000236` is not obtainable, and this project will not
>    ask again. The single-variable comparison that would have settled this cannot be run by anyone
>    outside WeCreat.
> 2. **LightBurn's reference machine does not represent the installed base.** Every "it works on
>    ours" result from LightBurn describes hardware no customer has. That is worth knowing on both
>    sides, and is said here with no criticism implied — nobody chose it, it is simply what a
>    prototype loan means six months later.
>
> The version numbers below are still correct. The word "regression" was mine and Jon's, offered in
> good faith on incomplete information, and it is withdrawn.

**Grade:** CONFIRMED-community (the version strings) · CONFIRMED-vendor (what the versions are)

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

**The working machine is on the older firmware.** Four increments older — and, as established on
2026-08-31, a **prototype build that was never shipped to anyone**.

## Why the version difference still matters

Every other explanation on the table is a property of the *design* — the status report, the buffer
mismatch, `G91` amplification, the streaming architecture. A design does not differ between two
units of one model. **A firmware build does.**

That much survives the correction. What does not survive is the idea that this is a defect
introduced into a shipping product, with a range to bisect. `000236` never shipped. The comparison
is prototype against production, and prototypes differ from production for all sorts of reasons
that are nobody's fault.

It does still explain, without special pleading, why LightBurn's machine behaves differently from
this one — and it means their reference unit cannot stand in for a customer's.

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

So the honest statement is: **two machines of the same model — one production, one prototype — at
speeds that should have favoured the failing one, produced opposite outcomes.**

It is not proven and cannot be proven here. `000236` is not obtainable, so the single-variable
downgrade comparison is unavailable to anyone outside WeCreat. WeCreat has the changelog between the
two builds and has said all their testing goes forward on `000240`.

**What this project can still do, with no vendor cooperation required:** run the same fill at
87,000 mm/min. That tests the starvation model directly on the production firmware, and it is now
the most informative experiment left in reach.

## The question for other owners — reframed 2026-08-31

The original ask was *"which firmware versions are affected"*. That was the right question when
`000236` looked like a released build. It is much less useful now: **if `000240` is what every
backer received, most owners will simply report `000240`**, and a list of identical version strings
proves nothing.

**The useful question is now sharper:** *do other `000240` machines do this too?*

- **Other `000240` owners also see stalls and drift** → it is the production firmware behaving as
  designed-but-flawed, and it affects everyone. Much stronger case.
- **Other `000240` owners run clean** → firmware is **not** the differentiator, and the cause is
  something local to this machine, this setup, or this cable. That would be unwelcome and extremely
  useful.

Either answer is worth more than the version string alone. What a usable report needs:

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
