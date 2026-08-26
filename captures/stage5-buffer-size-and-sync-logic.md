# Target Buffer Size won't persist — and why that may not matter

**Date:** 2026-08-26 · **LightBurn 2.1.04** · **Contributor:** Lee Gillie

## Observed

Typing `40` into **Target Buffer Size** and clicking OK reverts the field to **128**. The value is
editable but does not stick.

## Documented limits: none found

LightBurn's documentation does not state a minimum, maximum, or default for this field. The only
substantive discussion found is a forum thread where **two moderators disagree about whether
LightBurn uses the value at all** — one describing it as the controller's serial RX buffer size,
another replying *"As far as I know this information isn't used by Lightburn."* No LightBurn staff
clarified.

<https://forum.lightburnsoftware.com/t/how-to-tell-lightburn-what-my-target-buffer-size-is/122165>

So: undocumented, and possibly inert. Treat the snap-back as a clue rather than an obstacle.

## ⚠️ The reasoning step that matters more than the field

**If Synchronous transfer mode still stalls, buffer size is irrelevant.**

| Mode | Behaviour |
|---|---|
| **Buffered** | Send ahead up to the buffer target, track acknowledgements as they return |
| **Synchronous** | Send one line, **wait for its `ok`**, send the next |

Synchronous is the most conservative possible sender. There is no buffer to overrun. So:

- **Synchronous stalls** → the controller **failed to return an `ok`**. That is an acknowledgement
  fault, and **no buffer setting can fix it.**
- **Synchronous is clean, Buffered stalls** → it *is* an overrun, and buffer size is the right
  lever — worth fighting the UI for.

The earlier report was *"I have made the settings changes, but none helped"*, which appears to have
included Synchronous. If that is right, **buffer tuning is a dead end** and the effort belongs
elsewhere.

**This needs confirming explicitly**, because it decides whether the next hour is well spent.

## Forcing the value anyway — `captures/TEST-buffer40.lbdev`

A profile with `"TargetBufferSize": 40` baked in, under a distinct name so it cannot be confused
with the working device:

- DisplayName **ZZ TEST3 - Buffer 40**
- GUID `ZZTEST3B40`
- Carries `M18S0` as `StartGCode` (harmless — this device class ignores it; the User Start Script
  is what works)

Import it and open Device Settings. Three possible outcomes, all informative:

| Result | Meaning |
|---|---|
| Field shows **40** | The UI validation is what rejects it; the value is settable via import |
| Field shows **128** | LightBurn clamps or derives it — likely from the `wecreat` GCode flavor |
| Import rejected | The value is out of an enforced range |

## If buffer size turns out to be inert

Remaining levers, in order:

1. **Baud 1,000,000 → lower.** Reinstated as a suspect once the "MakeIt proves the serial link is
   fine" premise was corrected — MakeIt does not use the serial path for jobs
   ([analysis](stage5-stall-analysis-round2.md))
2. **Prefer Offset Fill.** Not a fix, a 10× reduction in blast radius
   ([evidence](stage5-G91-relative-mode-CONFIRMED.md))
3. **The upload bridge** over `192.168.42.1` — what MakeIt actually does, and the only approach
   that does not depend on the acknowledgement protocol being correct

If the fault really is missing `ok` responses, item 3 stops being deferred scope. No LightBurn
configuration can fix a controller that does not answer.

---

## ✅ RESULT: LightBurn clamps it. Buffer size is not settable.

`captures/TEST-buffer40.lbdev` carried `"TargetBufferSize": 40` in the file. After import, the
field **still reads 128**.

So the value is overridden on import as well as in the UI. Two independent routes, same answer:

> **`TargetBufferSize` cannot be changed on this device class. LightBurn derives or clamps it.**

Most likely it is fixed by the `wecreat` GCode flavor, which is consistent with LightBurn having
built-in WeCreat handling.

**This closes the buffer-size line of investigation.** It was the most promising untested lever;
it turns out not to be a lever at all. Recorded so nobody spends another hour on it.

### What that leaves

| Lever | Status |
|---|---|
| Target buffer size | ❌ **closed — not settable** |
| Transfer mode Synchronous | reported "no help" — worth one explicit confirmation, because if a one-line-at-a-time sender still stalls, the fault is a missing `ok` and no LightBurn setting can fix it |
| Baud rate | untested; back in play since MakeIt does not use the serial path |
| `Raster Move` template to eliminate `G91` | **untested, offline, highest value** — removes the *amplifier* even if the fault remains |
| Upload bridge over `192.168.42.1` | the architecture that avoids streaming altogether |
