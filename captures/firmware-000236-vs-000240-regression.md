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

## What this does NOT establish — the same caveat as the Flex result

**The comparison is not yet matched.** Jon's report of drift-free fills does not state:

- the **source** used
- the **speed**
- the **fill type** — plain `Fill` is 99.97 % `G91` relative, `Offset Fill` only 8.6 %
  ([evidence](stage5-G91-relative-mode-CONFIRMED.md))

The fills that fail here run at **12000 mm/min on the 100 W MOPA**. A slower job never empties the
buffer and completes regardless of firmware
([the same confound that limits the Flex result](community-01-lumos-flex-chris-zambesi.md)).

So the honest statement is: **two machines of the same model, on different firmware, produced
different outcomes on nominally similar work.** "Regression" is Jon's reading and a reasonable one.
It is not yet proven, and this project cannot prove it alone — there is no public firmware archive,
so downgrading `000240` to `000236` and re-testing is not something an owner can do.

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
| This project's Ultra | `000240` | 100 W MOPA @ 12000 mm/min | **stalls, drifts** |
| LightBurn dev team's Ultra | `000236` | not stated | clean |
| Chris Zambesi's Lumos Flex | not reported | diode, speed not stated | clean |

## Actions

1. **Report the version pair to WeCreat.** This is public forum information, so there is no
   confidentiality issue, and it gives them a specific range to look at rather than a symptom.
2. **Ask owners for version strings** alongside their results — the owners' group post now does.
3. **Ask Jon for source, speed and fill type**, to close the remaining gap in the comparison.
4. **Ask WeCreat whether `000236` is obtainable**, and whether downgrading is supported. If it is,
   this becomes a controlled single-variable test on one machine — the cleanest possible evidence.
