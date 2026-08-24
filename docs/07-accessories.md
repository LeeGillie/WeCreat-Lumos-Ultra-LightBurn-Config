# 07 — Accessories: Rotary, Slide, Conveyor

## Rotary Pro — the most promising accessory

**Specs (vendor):** chuck 3–100 mm diameter, sphere 10–37 mm, ring 10–37 mm, tilt 0–180°,
247 × 81 × 101 mm, 0.971 kg. With the Slide Extension: up to 380 mm long.

**Vendor lists LightBurn as supported software** for the Rotary Pro — the spec row reads
literally `Software  WeCreat MakeIt!  LightBurn`. Caveat: that page's compatibility row says
"Lumos / Lumos Flex", not Ultra, even though a "Rotary Pro for Lumos Ultra" variant is sold.

**Why this is the most likely accessory to work:** on a GRBL-typed device, LightBurn's ordinary
rotary support applies, and **rotary settings live inside the device profile**. WeCreat's own
Lumos profile carries them:

```json
"rotaryAxis": 3,
"rotarySteps": 360,
"rotaryDiameter": 86,
"rotaryIsChuck": true,
"rotaryMode": false,
"mirrorRotaryOutput": false
```

WeCreat's own tumbler guide for other models instructs LightBurn users to **"Set Axis to A"**.
The Vision passthrough conveyor is likewise driven through LightBurn's rotary setup as an A axis
with 360 mm per rotation.

**What needs determining on the Ultra:** the axis letter, steps per rotation, direction, and
whether any enable command is required.

**Marketing caution:** WeCreat also advertises "34-inch baseball bats". 34 in = 864 mm, which
contradicts the 380 mm figure given for rotary+slide. Treat the bat claim as belonging to a
different machine.

---

## Slide Extension

**Specs (vendor):** 520 × 183 mm working area, "2.2× expanded workspace", precision linear screw
drive. $349 pre-order, shipping from September 2026.

**The problem.** LightBurn's mechanism for engraving beyond a galvo field is **Split Marking**,
added in 2.1 — and it is a **galvo-class feature**. On a GRBL-typed device it does not exist.
Split Marking also requires the linear table to be driven by the controller's own motor output
with steps-per-unit configured in LightBurn, which is a galvo device-settings screen.

**What may still be possible:**

- Driving the slide as an additional axis through custom G-code, once its axis letter is known.
- Manual tiling: run the left half, advance the slide by a known amount with a macro, run the
  right half. Crude, but it works and needs nothing from LightBurn.
- A bridge (Path B) that intercepts and orchestrates.

**Prior art is discouraging.** Nobody has publicly made rotary + slide work in LightBurn on any
Lumos. LightBurn staff, July 2025: they asked WeCreat for device configuration and firmware
documentation and *"didn't hear back."* WeCreat's native software reportedly restricts
rotary+slide to unidirectional movement.

**First step:** Stage 5 differential capture — run a slide job in MakeIt and find the axis word.

---

## AutoFlow Conveyor

**Specs (vendor):** 10 kg load capacity, plug-and-play, "SmartFill for Batch Automation" using
the 50 MP camera. $499 pre-order, shipping from September 2026.

**Working area — vendor sources disagree:**

| Source | Figure |
|---|---|
| Main product spec table | 1000 × 200 mm (Batch Feeding) |
| Conveyor product page | up to 200 × 500 mm |
| Kickstarter FAQ | 206 × 206 mm per cycle |

Most plausible reconciliation: 206 × 206 mm is the per-pass galvo field on the belt, 500 mm the
initial loading area, 1000 mm the total fed length. **INFERRED.**

**Precedent:** the Vision's passthrough conveyor *is* usable from LightBurn — WeCreat published a
guide for it, driving the feeder through LightBurn's rotary setup on the **A axis** with preset
parameters. If the Ultra's conveyor is addressed the same way, this is more reachable than the
slide.

**What is almost certainly not reachable:** SmartFill camera-driven batch layout, item detection,
and camera-triggered registration. Those are on-machine features with no third-party interface.

**Unknowns:** feed increment per cycle, whether the belt is bidirectional or advance-only, and
the feed command itself.

**Safety note.** The conveyor exists to run long unattended batches. See
[SAFETY.md](../SAFETY.md#fire).

---

## The `M16` / `M17` "U mode" question matters here

Those two codes appear in the start block of every WeCreat profile. One live hypothesis is that
"U" is a fourth axis. WeCreat's own rotary documentation says the rotary axis is **A**, which
mostly refutes that — but it leaves the slide and conveyor unaccounted for. If either turns out
to be a "U" axis, `M16`/`M17` acquire an obvious meaning.

A Stage 5 capture of a slide job and a conveyor job would settle both questions at once.
