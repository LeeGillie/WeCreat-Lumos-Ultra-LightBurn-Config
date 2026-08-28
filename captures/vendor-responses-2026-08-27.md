# Vendor responses — WeCreat and LightBurn both engaged, 2026-08-27

**Evidence grade: CONFIRMED-vendor.** Four responses within ~24 hours of publication, two from
WeCreat support and two from LightBurn staff — one of them a LightBurn **developer** with the
hardware in hand.

**Headline: a LightBurn developer independently confirmed the dropped-move mechanism, and the
upload-based fix this project identified as "the architecturally correct answer" is already being
built.**

---

## 1. LightBurn Dev Team — Jon C (`goeland86`), 11:23 UTC ⭐ the important one

> *"the buffer on the Lumos Ultra is unfortunately **not fully usable**. It seems that the buffer to
> which we send commands through the serial port and the buffer used by the chip executing moves
> don't have the same size."*
>
> *"What I found … is that if I set the buffer at **127 or bigger, it would just drop moves from the
> job to process**. So yes, I'm aware and discussing with WeCreat how to resolve the issue."*
>
> *"With 127 bytes of buffer, for a galvo machine we're going to be running 'dry' very quickly."*

**This is independent confirmation of the dropped-move mechanism**, from someone with both the
machine and the source code, reached without seeing our G-code analysis.

It also completes the causal chain we could only see one end of:

```
WeCreat firmware returns no OPT: in its $I response
        ↓
LightBurn falls back to a 128-byte buffer
        ↓
at ≥127 bytes the controller DROPS MOVES          <- Jon C, confirmed on hardware
        ↓
dropped move inside a G91 relative block          <- our measurement
        ↓
every later position inherits the error           <- 2.30 mm outside declared bounds
```

**Two independent lines of evidence, from opposite directions, meeting in the middle.**

Note the second sentence: the serial receive buffer and the motion-executing chip's buffer are
**different sizes**. That is a controller architecture problem, and it fits what this project
reconstructed — an Allwinner SBC front-end with a separate motion MCU
([docs/01](../docs/01-architecture.md)).

## 2. LightBurn Support — Aaron F, 09:46 UTC — why the buffer size won't stick

> *"LightBurn reads the buffer size (in bytes) from the output of **`$I`**. Normally GRBL will output
> an `OPT:` and return the RX buffer's byte size there. However if that response is missing,
> LightBurn defaults to 128 bytes again."*
>
> *"Manually setting the buffer size **should** override that behavior. **We have a fix in place** to
> solve this. (not sure if it already made it to version 2.1.04)"*

So the reason `TargetBufferSize` reverted from 40 to 128 — in the UI *and* on import — is a
**known LightBurn bug with a fix already written**. The trigger is WeCreat firmware not returning
`OPT:` in `$I`.

> ### 📄 A note on how WeCreat's replies are reported here
>
> **The two WeCreat sections below are summarised, not quoted.** They previously carried verbatim
> extracts from support email; those have been replaced with paraphrase.
>
> WeCreat asked that specific internal email text stay within the direct thread, while explicitly
> welcoming the reporting of findings, progress and outcomes to the community. That is a reasonable
> ask, it matches what this project told them it intended to do, and the substance below is
> unchanged — only the wording is now this project's rather than theirs.
>
> LightBurn's sections are left quoted, because those are **public forum posts** rather than
> private correspondence.

## 3. WeCreat Support — Allen, 09:19 UTC — on the streaming report

*Summarised.*

WeCreat confirmed that nearly all of this project's findings are correct, and consistent with what
they had already been discussing with LightBurn. They reported real progress: LightBurn is
implementing WeCreat's proposal to **upload the job to the machine's internal memory rather than
transmitting it in real time**, and said test builds for owners wanting to drive the Ultra from
LightBurn ahead of general release were close.

**The upload bridge is being built.** [ROADMAP](../ROADMAP.md) listed it as deferred scope and
`captures/stage5-streaming-stalls.md` argued it was the architecturally correct answer. It is
already in flight between the two companies.

**Open at the time:** which finding was *not* correct. Answered on 2026-08-28 — see below.

## 4. WeCreat Support — Allen, 09:57 UTC — a published spec was wrong

*Summarised.* On a separate thread about the Ultra's claimed UV spot size.

WeCreat confirmed that the previously published **`0.0019 mm` figure was not the UV spot size at
all** — it described the machine's motion accuracy, and the two parameters had been incorrectly
associated in their materials. They gave the actual spot size of the 355 nm UV source as
**approximately 6–8 μm**, agreed that a 1.9 μm spot was physically unreasonable as this project had
argued, and said they would revise the affected materials.

**A published manufacturer specification is being corrected because a customer asked.** The
`0.0019 mm` figure appears in [docs/02](../docs/02-feature-inventory.md) row A1, sourced from
WeCreat's own product page; that row now reads **6–8 μm**, with 1.9 μm recorded as motion accuracy.

Also confirmed in the same message: MakeIt's 256 layers is **8-bit processing** — a software
representation limit rather than a controller capability.

Allen also took on the role of ongoing point of contact.

## 5. WeCreat Support — 2026-08-28 — the outstanding question, answered

*Summarised.*

**Which finding was not correct: the eyewear claim, and it was not a LightBurn finding at all.**

WeCreat confirmed that on LightBurn compatibility, the issues identified were **all correct**. The
one thing this project had wrong was in [SAFETY.md](../SAFETY.md): it stated that one pair of
goggles cannot cover both sources. WeCreat states that the protective glasses **officially supplied
with the machine are designed to protect against both the 355 nm UV and the 1064 nm IR
wavelengths**.

[SAFETY.md](../SAFETY.md) was corrected the same day, with the correction left visible rather than
edited away, and with two limits stated: it applies to WeCreat's supplied eyewear rather than to
third-party goggles generally, and *"designed to protect against"* is a vendor statement rather
than a certified optical-density rating. **OD figures and the certification standard have been
requested.**

*Their message gives the IR wavelength as "1024 nm"; 1064 nm is certainly meant — it is engraved on
the lens.*

**Also in that reply:** LightBurn has delivered a dedicated build implementing the file-upload path,
together with configuration files, and WeCreat has asked this project to test it and report back.
WeCreat asked that the build itself and its details stay private for now, so **no link, build
identifier, or configuration file appears in this repository**, and none will until they say
otherwise. Progress and results can be reported; the software cannot be redistributed.

**On publishing generally**, WeCreat confirmed that sharing high-level progress, solutions and
outcomes with the community and in this repository is welcome and encouraged, and asked only that
specific internal email text, proprietary build details and unreleased software stay within the
direct thread. This document now follows that.

---

## ✅ What this project got right

| Finding | Status |
|---|---|
| Status report state field is fabricated | Confirmed by WeCreat, along with nearly all other findings |
| Moves are being dropped, not merely delayed | **Confirmed independently** by a LightBurn dev |
| `G91` turns a dropped move into permanent drift | Mechanism intact; the drop is now confirmed |
| Buffer size is not settable | Confirmed — and the *cause* is now known |
| The upload path is the right architecture | **Already being implemented** |
| MakeIt avoids this because it does not stream | Consistent with WeCreat's own account |

## ❌ What this project got wrong

**`captures/stage5-buffer-size-and-sync-logic.md` concluded:**

> *"This closes the buffer-size line of investigation. It was the most promising untested lever;
> it turns out not to be a lever at all."*

**That was wrong.** Buffer size is *exactly* the lever — Jon C reports that ≥127 drops moves, so a
lower value is precisely what is needed. The correct conclusion was narrower: *the value cannot
currently be set*, because of a LightBurn bug that already has a fix written.

The reasoning error was treating "I cannot change this" as "this does not matter". Recorded rather
than quietly edited, in keeping with how the rest of this repo handles its mistakes.

A second, softer miss: the argument that *"if Synchronous mode still stalls, buffer size is
irrelevant"* now looks unsafe. It assumed a synchronous sender keeps nothing in flight, which may
not hold here given the two mismatched buffers Jon C describes.

## What to do next

1. ~~**Ask which finding is not correct.**~~ **Answered 2026-08-28** — it was the eyewear claim in SAFETY.md, now corrected. All LightBurn compatibility findings confirmed
2. **Ask about the test builds** — this project has a machine, published captures, and a documented
   method. Good candidate for early testing
3. **Update `docs/02` A1** — UV spot size 6–8 μm, not 0.0019 mm; note 1.9 μm is motion accuracy
4. **Watch for the LightBurn buffer-size fix.** Once the value can be set, test below 127 —
   that is now a specific, evidence-backed experiment rather than a guess
5. **Re-scope the ROADMAP.** The blocker has an owner, a diagnosis and a fix in progress. It is no
   longer this project's problem to solve — only to test and document
