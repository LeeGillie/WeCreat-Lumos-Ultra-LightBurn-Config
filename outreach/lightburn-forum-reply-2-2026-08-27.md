# POSTED 2026-08-27 — corrective reply on the LightBurn forum thread

> **Sent, and it landed.** Jon C replied by conceding that LightBurn may have been sent in-flight
> firmware, and Mike Hembrey with *"Not really, just out of sequence. You posted both, and that is
> what counts."* Retracting specific sentences cost nothing and raised standing in the thread.

**Where:** reply in the existing topic, after Jon C's ncviewer post.
**Superseded:** an earlier draft, deleted — the thread moved on before it could be posted.

**What this post does:** withdraws the speculation in my previous post, answers the ncviewer
challenge with measurements that already existed, concedes the weak edge in the 2.30 mm figure
before anyone else finds it, and asks the one question that now matters most — the firmware version
on LightBurn's own machine.

**Format note:** Discourse renders Markdown natively. Paste everything below the line as-is.

---

@goeland86 — fair challenge, and let me start by withdrawing my previous post, which was the first
thing I have put in this thread that was theory rather than measurement. That was a mistake and I
would rather correct it than defend it.

**Specifically, what I am taking back:**

- *"the serial communication is glitchy, once in a while some data is lost — that's what we think is
  happening."* That was a hypothesis stated as though it were established. It is not mine to state.
  The only actual evidence for dropped data in this thread is yours: that the machine drops moves at
  a buffer of 127 or larger.
- *"our stuff never made it to the gc."* Vague and unhelpful. What I should have said: I defined the
  **Raster Move** template as `G1 X{x} Y{y} S{power} F{speed}`, saved the G-code, and `G91` was still
  present throughout. So the template does not control relative emission — it controls line
  formatting only. That is a result, not a failure.
- The suggestion that other WeCreat generations likely share the same fault. I have no data on any
  machine but this one. Withdrawn.

**Now the ncviewer question, which I should have answered directly.**

The generated G-code does not drift. I checked it two ways before posting anything:

1. I wrote a converter that rewrites the whole fill from relative to absolute. The converted
   coordinate range matches the file's own `;Bounds: X48.784 Y82.637 to X123.216 Y125.199` **exactly**.
2. The drift measurement never came from the G-code at all. It came from the controller's own
   report at end of run: `<Idle|MPos:-47.968,-24.663,...>`. Through this machine's confirmed −105
   field-centre offset that is Y **80.337**, against the job's own declared minimum of **82.637** —
   2.30 mm below it.

So the file says one thing and the machine says another. That is what "the drift is in what got
executed" was meant to convey, and I should have shown the numbers instead of asserting it.

**The weak edge in that measurement, before anyone else finds it.**

That run is not clean. It is a run where I had used Pause/Resume repeatedly to unstick a stall — the
console log shows unbalanced `!` and `~` — and a feed hold stops mid-move, which in relative mode is
itself a drift source. So I cannot separate "dropped move" from "my own recovery attempt" in that
particular number.

What I can say is narrower and still holds: **a pure `G90` job cannot end outside its own declared
bounds at all**, by construction. Something is accumulating.

I can produce a clean version — run a dense fill, never touch Pause/Resume, abort on stall, and
report the final `MPos` against the declared bounds. If that is useful I will run it this week.

**The question I would most like answered, though, is yours:**

> *"On our machine, G91 worked… So I suspect a firmware update not yet released to the public."*

**What firmware version does your machine report?** Mine identifies as:

```
[WeCreat Lumos :ver 000240]
```

If yours differs, that reframes this entire thread. It would mean the behaviour is already fixed and
simply has not shipped, and the useful question becomes how owners get that build rather than what
is wrong with the controller.

@MikeyH — no argument from me. Your machine is not an Ultra, so a run on it would not be a control,
and I should not have left that request hanging. Thank you for downloading it anyway.
