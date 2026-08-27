# Draft — third reply on the LightBurn forum thread

**Where:** LightBurn forum, WeCreat category — same topic.
**Position in thread:** after the corrective post, which Jon and Mike both responded to well.

**What this post does:** stops asking and starts giving. Three measurements off WeCreat's own
staged job file, one of which (mid-job `M38`/`M39`) is directly useful to LightBurn's Q-Pulse work
and was not previously documented anywhere. One forward-looking question. No re-apologising — that
is done.

**Format note:** Discourse renders Markdown natively. Paste everything below the line as-is.

---

Some measurements rather than opinions this time.

MakeIt is an Electron app and it stages the complete generated job on the PC before uploading it,
which means WeCreat's own toolpath output can be read directly — no packet capture, nothing sent to
the machine:

```
%APPDATA%\Wecreat MakeIt!\gcode\gcode.gc
```

I ran the last one I made through a streaming analyser. Three things in it may be useful to you.

---

**1. Mid-job MOPA parameter changes — this is the one I think you can actually use.**

```
M38  (frequency)     282
M39  (pulse width)   282
```

282 of each, inside a single job. A small single-layer job I captured earlier has exactly one of
each. So this firmware accepts frequency and pulse-width changes **mid-job**, and WeCreat's own
software relies on that heavily — opening values `M38F60` / `M39P250` here, `M38F151` / `M39P200`
in the other job.

Relevant because LightBurn exposes **Enable Q-Pulse Options** on this device class. Whatever that
currently emits, the controller clearly has per-layer pulse control and the vendor drives it that
way as a matter of course.

---

**2. Scale, which I think reframes the buffer discussion.**

That job file is:

| | |
|---|---|
| Size | **232,835,780 bytes** (222 MB) |
| Lines | **11,276,586** |
| Motion commands | **11,275,714** |
| Average line | 20.6 bytes |
| Footprint | ≈ 42 × 42 mm |

One job. Single header, single `M6` terminator — not an accumulating log.

At 1,000,000 baud, 8N1, that is 100,000 bytes/s ceiling:

```
232,835,780 ÷ 100,000 ≈ 2,328 s ≈ 39 minutes
```

— pure payload, perfect line utilisation, zero acknowledgement round trips. A ~128-byte window over
20.6-byte lines means about six lines in flight across 11.3 million of them.

I raise it only for scale. It suggests that on this machine the buffer size sets how *gracefully*
streaming fails rather than whether it works, and that the upload path you and WeCreat are building
is the only thing that makes a job like this reachable from LightBurn at all. Which you already
know — but I had not appreciated the magnitude until I measured it.

---

**3. Absolute vs relative, with the caveat attached.**

```
G90 switches : 2
G91 switches : 0
moves ABSOLUTE : 11,275,714  (100.00 %)
moves RELATIVE :          0  (  0.00 %)
```

Zero `G91` in 11.3 million moves. Against LightBurn `Plain Fill` on the same machine: 9,634 of
9,637 relative, two absolute re-anchors in the entire job.

**The caveat, before anyone has to raise it:** this is not evidence that WeCreat chose absolute
deliberately. They upload, so they have no bandwidth to save — `G91` is a streaming optimisation and
they do not stream. The choice is probably incidental.

What it does establish is narrower: the controller's absolute path is exercised at eleven-million-
move scale on every MakeIt job, so there is no concern that `G90` is a cold or slow path on this
hardware.

---

**The one question I would ask:**

Does the Q-Pulse option on the `wecreat` flavor emit per-layer `M38`/`M39`, or is pulse control
currently job-global? If per-layer is achievable, MOPA on this machine becomes considerably more
capable in LightBurn than it is today, and finding 1 says the firmware side is already there.

Two incidental corroborations, for whatever they are worth: the file's own header reads
`;canvas border: 0 0 210 210` and it opens with `M107X-105Y-105`, which independently confirms the
210 × 210 field and the −105 origin offset I had only measured before.

The analyser is a small read-only PowerShell script and is in the repo with everything else, if
anyone wants to point it at their own machine's output:

https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config

On the drift measurement I offered earlier: I will still run it cleanly, but for my own records
rather than as anything anyone should wait on. You have the mechanism from your side, and my number
would not change it. I would just rather not leave a contaminated measurement standing in my own
documentation. And I will try a sub-127 buffer the moment the override sticks.
