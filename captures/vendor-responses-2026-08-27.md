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

## 3. WeCreat Support — Allen, 09:19 UTC — on the streaming report

> *"**Almost all of your findings are correct**, and they are consistent with what we have been
> communicating with LightBurn. In fact, we have already made some good progress with LightBurn.
> They are currently working on implementing **our suggestion to upload the job directly to the
> machine's internal memory instead of transmitting it in real time**."*
>
> *"We are now in the final stage of wrapping things up, and we should be able to have some **test
> builds available soon** for users who would like to try controlling the Lumos Ultra with LightBurn
> ahead of the official release."*

**The upload bridge is being built.** [ROADMAP](../ROADMAP.md) listed it as deferred scope and
`captures/stage5-streaming-stalls.md` argued it was "the architecturally correct answer". It is
already in flight, between the two companies, and test builds are close.

**Open:** *"almost all"* is unspecified. Worth asking which finding is wrong — this project would
rather correct it than leave it standing.

## 4. WeCreat Support — Allen, 09:57 UTC — a published spec was wrong

On a separate thread about the Ultra's claimed UV spot size:

> *"The previously published **'0.0019 mm' figure was not the actual UV laser spot size**, but rather
> a parameter describing the machine's motion accuracy. In our previous materials, these two
> parameters were incorrectly associated…"*
>
> *"the actual spot size of the 355 nm UV laser on the Lumos Ultra is **approximately 6–8 μm**."*
>
> *"your original conclusion that a 1.9 μm UV laser spot size is physically unreasonable was
> correct. Thank you for pointing this out. **We will also revise the relevant materials**."*

**A published manufacturer specification is being corrected.** The `0.0019 mm` figure appears in
[docs/02](../docs/02-feature-inventory.md) row A1, sourced from WeCreat's own product page — that
row now needs updating to **6–8 μm**, with the 1.9 μm figure recorded as motion accuracy.

Also confirmed in the same message: MakeIt's 256 layers is **8-bit processing**, i.e. a software
representation limit rather than a controller capability.

Allen has also assigned himself as ongoing point of contact.

---

## ✅ What this project got right

| Finding | Status |
|---|---|
| Status report state field is fabricated | "Almost all of your findings are correct" |
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

1. **Ask Allen which finding is not correct.** "Almost all" is the only unresolved claim
2. **Ask about the test builds** — this project has a machine, published captures, and a documented
   method. Good candidate for early testing
3. **Update `docs/02` A1** — UV spot size 6–8 μm, not 0.0019 mm; note 1.9 μm is motion accuracy
4. **Watch for the LightBurn buffer-size fix.** Once the value can be set, test below 127 —
   that is now a specific, evidence-backed experiment rather than a guess
5. **Re-scope the ROADMAP.** The blocker has an owner, a diagnosis and a fix in progress. It is no
   longer this project's problem to solve — only to test and document
