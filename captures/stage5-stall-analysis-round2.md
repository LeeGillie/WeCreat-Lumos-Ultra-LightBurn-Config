# Stall analysis, round 2 — reviewing a second opinion

**Date:** 2026-08-26 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie
**Context:** an independent ChatGPT diagnosis was obtained and is assessed here on its merits.

## New symptoms reported

- Engraving **freezes mid-job**; Pause → Resume restarts it *"mostly"* from where it stopped
- After a restart, **all remaining artwork was shifted to the right**
- With **Offset Fill**, the *same letters* were repeatedly left partly engraved
- Plain **Fill** behaves differently but still stalls
- The job **never signals completion** — fan keeps running, Stop is always required
- First run of the day (machine powered overnight) was the only clean one

## ❌ The premise the second opinion rests on is wrong

> *"WeCreat MakeIt works flawlessly over the exact same direct USB connection."*

**MakeIt does not send job data over the serial port.**

This project established that directly ([Stage 5](stage5-framing-mopa-benchy.md)): a 302 MB
`gcode.gc` was found on the controller's SD card at `/mnt/SDCARD/data/printing/`. MakeIt **uploads
jobs over the RNDIS network gadget** — the same private `192.168.42.1` network that LightBurn's own
built-in WeCreat camera preset uses for the camera.

One cable, **two independent transports**: a CH340 serial bridge *and* a Linux network gadget.
MakeIt's reliability exercises the network path. LightBurn streams over the serial path.

**So MakeIt working flawlessly is not evidence that the serial link is sound at 1,000,000 baud.**
It is barely evidence about the serial link at all.

Consequences:

1. **Baud rate returns as a legitimate suspect.** The second opinion explicitly advised leaving
   1,000,000 alone on the grounds that MakeIt proves it works. That reasoning does not hold. The
   Genmitsu comparison — a real GRBL device streaming happily — runs at **115,200**.
2. The 1 Mbaud figure came from **WeCreat's own Lumos profile**, so it is what the vendor
   configures. But a rate the vendor configures and a rate the vendor *depends on for job
   integrity* are different things.

## ⚠️ Two cited claims I could not corroborate

The diagnosis leans heavily on:

- *"A LightBurn developer documented that WeCreat firmware does not always return an `ok` after a
  `G91` command"*
- *"LightBurn 2.1 added: 'Allow for extra ok's from buggy WeCreat firmware'"*

**Searched; not found.** They may well be real — the search was not exhaustive — but they are
**unverified**, and the whole G91 theory is built on them. Do not treat them as established.

## ✅ What the new console log actually proves

```
Starting stream
M18 S0
!<Idle|MPos:2.748,18.237,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
~
Job halted
```

`!` is the GRBL **feed hold** real-time command. The controller answers it with **`Idle`**.

> **A machine that has just been told to hold, mid-job, reports `Idle`.**

That is the sharpest evidence yet that the **state field is fabricated**. Note also that `MPos`
here reads `2.748, 18.237` — live, mid-motion, non-integer. So:

| Field | Verdict |
|---|---|
| `MPos` | **live and correct** |
| machine state (`Idle`/`Run`/`Hold`) | **fabricated — always `Idle`** |
| `FS` (feed/speed) | **fabricated — always `0,0`** |

A sender pacing a stream against "always idle, never running, never held" is being lied to about
the one thing that matters. This is consistent with every symptom: stalls, no completion signal,
and recovery via `!`/`~` — which forces a state transition the status report never reports.

## 🎯 The G91 theory is testable offline, in seconds

The theory: fill operations emit `G91` relative moves; a lost acknowledgement drops one move; every
subsequent position inherits the error — which would explain artwork shifted to the right.

**Every `.gc` file captured so far is pure `G90` absolute**, with absolute coordinates on every
line ([`gcode-customgcode-air.gc`](gcode-customgcode-air.gc) and siblings). But those are *vector*
jobs. Whether **Fill** or **Offset Fill** emits `G91` is untested.

**Test — no machine, no beam, 30 seconds:**

1. Open the job that fails (the one with the troublesome letters), set to **Offset Fill**
2. **Save GCode** → `captures/gcode-offsetfill.gc`
3. Repeat with plain **Fill** → `captures/gcode-fill.gc`
4. Search both for `G91`

- **`G91` present** → the theory is live and worth pursuing
- **`G91` absent** → the theory is dead, and the shifted artwork needs a different explanation

Either answer saves hours. Send both files and they can be diffed against the vector captures.

## Settings already correct

A LightBurn moderator's fix for a WeCreat machine stuck **Busy after framing**
([forum thread](https://forum.lightburnsoftware.com/t/wecreat-and-lightburn-not-working-together-as-it-should-need-help/174621)):
disable Enable Z Axis, enable Relative Z Moves only, disable Optimize Z moves, disable Enable laser
fire button.

Checked against the live `prefs.ini`: `EnableZ=False`, `RelativeZOnly=True`, `OptimizeZ=False`,
`LaserFire_Enable=False`. **All four already correct.** That avenue is closed.

## Priority order from here

| # | Action | Cost | Why |
|---|---|---|---|
| 1 | Save Fill + Offset Fill G-code, search for `G91` | 30 s, no machine | Kills or confirms the leading theory outright |
| 2 | **`TargetBufferSize` 128 → 40 → 15** | minutes | **Never tested.** If the controller's real buffer is smaller than standard GRBL's, LightBurn overruns it — and this is exactly the shape of a buffer overrun |
| 3 | **Baud 1,000,000 → lower** | minutes | Reinstated as a suspect now the MakeIt premise is corrected |
| 4 | Upload bridge over `192.168.42.1` | a software project | Sidesteps streaming entirely — what MakeIt actually does |

Item 2 is the striking omission from both diagnoses so far, including my own.

## The structural read

If items 1–3 fail, this is not a configuration bug. It is a controller that cannot be reliably
streamed to, and **the vendor's own software does not stream to it either.** That is not a
coincidence — it is very likely *why* the acknowledgement protocol was never made correct.

In that case the `weburn`-style upload bridge stops being deferred scope and becomes **the only
architecture that works**, and v1.0's honest claim shrinks to small vector jobs.
