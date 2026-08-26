# Draft — WeCreat Lumos Ultra owners' group

*Tone: helpful neighbour, not vendor critic. Leads with safety, honest about what does not work,
asks for help. Trim freely — the first three lines are what most people will read.*

---

**I've been reverse-engineering LightBurn support for the Lumos Ultra, and I've put everything on
GitHub — including the parts that don't work yet.**

WeCreat publishes LightBurn configs for the Vision, Vision Pro, Vista and Lumos, but not the Ultra.
I've spent the last few days working out what it takes, and documenting everything I found on an
actual machine. It's free, it's open, and I'd welcome help.

👉 https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config

**Three things worth knowing even if you never touch LightBurn:**

**1. Don't import WeCreat's Lumos profile into an Ultra.** The Ultra identifies itself over USB as
`[WeCreat Lumos]` — it doesn't say "Ultra". So the official Lumos profile connects happily and
declares a **116 × 116 mm** workspace. The Ultra's field is **210 × 210 mm**. Jobs get silently
mis-scaled and mis-placed, with no error and no warning.

**2. In LightBurn, the Frame button can fire the beam.** This surprised me, and it's why the safety
notes come first. LightBurn's framing commands carry no power setting, so the machine uses whatever
power was left over from the previous job. On a gantry laser, framing is harmless. Not here. Goggles
on when you frame.

**3. The fiber source is 1064 nm — confirmed.** It's engraved on the red lens itself
(`SL-1064-200-F290-D10-C`). I can't find WeCreat publishing that figure anywhere. **UV goggles give
you nothing at 1064 nm.** Purple and green lenses are both 355 nm UV; only red is IR. One pair does
not cover both.

**What works in LightBurn today:** it connects, the geometry is correct (I measured the field —
no detectable distortion out to 200 mm), the camera works through LightBurn's built-in WeCreat
preset, and it marks properly. Vector work is fine.

**What doesn't:** long jobs stall part-way through. The reason is specific — the controller's status
report always claims the machine is idle, even mid-job, even when you tell it to pause. LightBurn
can't tell when the machine is busy, so the stream desynchronises. Fills are worst, because
LightBurn sends them as *relative* moves — one lost instruction shifts everything after it. I
measured a job finishing 2.3 mm outside its own bounding box.

Worth noting: **MakeIt never hits this, because MakeIt doesn't stream.** It uploads the whole job to
the machine's SD card and lets the controller run it locally. Completely different path.

**One thing you can do that I can't:** if you own a **Vision, Vision Pro, Vista or Lumos** and use
WeCreat's official LightBurn config — **does a big fill run start to finish without stalling?**

If yours runs clean and only the Ultra stalls, that's important. If yours stalls too, that's equally
important. Either answer helps a lot, and I can't test it because I only have the one machine.

Everything is documented with evidence grades — where I guessed I say so, and where I got something
wrong I left the mistake in with the correction beside it.

Happy to answer questions. And if you know more than I do about any of this, please say so — that's
rather the point of putting it up.
