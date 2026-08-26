# Draft — report to LightBurn

**Where:** LightBurn forum, WeCreat category (which today contains no Lumos Ultra topic at all),
and/or a support ticket. The forum is probably better — it is public, searchable, and other WeCreat
owners will find it.

**What you are giving them:** a precise, reproducible protocol observation with captures. Not a
complaint. LightBurn already ships WeCreat-specific handling, so someone there cares about this
machine family.

---

**Subject: WeCreat Lumos Ultra — controller status report never leaves `Idle`, streams desynchronise
on long jobs**

I've been building a LightBurn device configuration for the WeCreat Lumos Ultra (WeCreat publishes
configs for the Vision/Vista/Lumos but not the Ultra) and I think I've found a protocol-level
problem worth reporting. Everything below is from LightBurn 2.1.04 on a physical machine, and the
captures are public:

https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config

**Setup:** Custom GCode device, `GCodeFlavor: wecreat`, serial at 1,000,000 baud over the machine's
CH340 bridge. LightBurn detects it correctly — "Found WeCreat Device" — and emits WeCreat-specific
commands (`Exit_Preview_Mode`, `M41Y1`), so the built-in WeCreat support is working as intended.

**The observation: the status report's state field appears to be fabricated.**

Every `?` returns the same state regardless of what the machine is doing:

```
<Idle|MPos:2.748,18.237,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
```

- `MPos` **is live and correct** — it tracks real position, non-integer, mid-motion
- the **state field is always `Idle`**, including during an active job stream
- **`FS` is always `0,0`**, never reporting real feed or speed

The sharpest evidence: sending `!` (feed hold) mid-job, the controller answers **`Idle`**. A machine
that has just been told to hold reports itself idle.

**Consequence.** Long jobs stall part-way through and sit there — no alarm, no disconnect, fan still
running. Pressing Pause then Resume (`!` then `~`) restarts the stream from roughly where it
stopped. LightBurn reports `Stream completed in 0:00` for jobs that visibly take minutes.

That is consistent with LightBurn pacing a stream against a device that claims it is never running
and never held.

**Why it does real damage: `G91`.**

LightBurn emits fills as relative moves. Measured on one job:

| | Offset Fill | Plain Fill |
|---|---|---|
| Moves in `G91` relative | 1,009 (8.6 %) | **9,634 (99.97 %)** |
| Absolute `G0` re-anchors | 459 | **2** |

`Plain Fill` enters `G91` at line 21 and does not leave until line 8,647 — over 8,600 consecutive
relative moves with no absolute re-anchor.

So one lost or unacknowledged line shifts **everything after it, permanently**. I measured a job
finishing **2.30 mm outside its own declared `;Bounds:` header** — arithmetically impossible in a
pure `G90` job.

It also means the Pause/Resume recovery is itself harmful: a feed hold stops mid-move, and in
relative mode any imprecision on resume is inherited by the rest of the job.

**What I tried:**

- Query-for-position off, Laser Fire button off, Z axis off, relative-Z only, optimise-Z off (the
  known fix for WeCreat "Busy after framing") — no change
- Transfer mode Synchronous — no change reported
- **`Target Buffer Size` cannot be changed.** Typing 40 reverts to 128, and importing a `.lbdev`
  with `"TargetBufferSize": 40` still shows 128. Is this clamped by the `wecreat` flavor? If so it
  might be worth exposing, or documenting
- Defining the **Raster Move** template does not affect `G91` — it changes only line formatting

**Questions I'd genuinely like answered:**

1. Is there any way to make LightBurn emit fills in absolute coordinates? On a controller with an
   unreliable stream, `G91` converts a recoverable glitch into a ruined workpiece. Even a hidden
   option would help.
2. Is `Target Buffer Size` intentionally fixed for this device class?
3. Does LightBurn's WeCreat handling assume a status report that this firmware does not provide?

I'm aware the root cause is likely WeCreat's firmware, not LightBurn — I'm reporting it to both. But
the `G91` amplification is the difference between "occasionally stalls" and "occasionally destroys
the work", and that part sits on LightBurn's side.

Happy to provide the full `.gc` files, console logs and device profile — they're all in the repo.
