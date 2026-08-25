# Stage 4, Test 1 — console returns a `G0` flood, no status reports

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04** · **COM7**
**Contributor:** Lee Gillie · **Status:** 🔴 UNEXPLAINED — blocks Test 1

## What was sent, and what came back

Operator typed, in order: `?` · `G90` · `G0X10Y10` · `?` · `G0X0Y0` · `?` · `$$`

Between and around every one of those, the console filled with **bare `G0` lines** — dozens of
them, continuously, with no coordinates and no parameters:

```
?
G0
G0
G0
...  (~24 lines)
G90
G0
G0
...  (~20 lines)
G0X10Y10
G0
...  (~12 lines)
?
G0
...  (~21 lines)
G0X0Y0
...
$$
G0
(blank)
G0
...
```

## What is missing

| Expected | Seen |
|---|---|
| `ok` after each accepted command | **none** |
| `<Idle\|MPos:0.000,0.000,0.000\|FS:0,0\|Pn:Z\|WCO:...>` in reply to `?` | **none** |
| A settings dump, or a stub reply, from `$$` | **none** |

All three of those **were** seen on this same machine during
[Stage 3](stage3-lightburn-connect-benchy.md) — the status report in particular is quoted there
verbatim. So the controller is capable of producing them. Something about this session differs.

## Leading hypothesis

LightBurn polls a connected device for status roughly 4×/second. If the controller is answering
that poll with the literal string `G0` instead of a GRBL `<...>` status report, the result would
look exactly like this: a steady background stream of `G0`, unrelated to operator typing, with the
operator's own commands interleaved wherever they happened to land.

**Test that separates it:** stop typing and watch the console for ~10 seconds. If `G0` lines keep
arriving with no input, they are inbound traffic, not an echo of anything sent.

## Alternatives not yet excluded

| Hypothesis | How to check |
|---|---|
| Machine is not powered on / not really connected | Scroll the console to the connect moment. Is `[WeCreat Lumos :ver 000240]` + `Found WeCreat Device` there? |
| Console is showing sent traffic only, replies suppressed | Does the **Move window's position readout** change after `G0X10Y10`? That only updates from status reports |
| Firmware echoes commands rather than acking | Would not explain bare `G0` with no coordinates, nor a flood between typed lines |
| Control-mode latch in an odd state | Power-cycle the Lumos, reconnect, retry `?` once |

## Why this blocks Test 1

Test 1 asks whether `MPos` tracks commanded coordinates. Without a status report there is no
`MPos` to read, so the question is unanswerable as written. **Test 1 is inconclusive, not failed.**

Note this does **not** invalidate Test 2 — the corner-landing test needs the red pointer and a
pair of eyes, not a status report.

## Status

Open. Diagnosis needed before Stage 4 continues.
