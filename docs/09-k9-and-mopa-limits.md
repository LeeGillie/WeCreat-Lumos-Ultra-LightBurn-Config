# 09 — The Two Hard Walls: MOPA Pulse Control and K9 Internal Engraving

Two capabilities that make the Lumos Ultra interesting are the two least likely to be reachable
from LightBurn. Both fail for the *same underlying reason*, and it is not a missing config file.

---

## Wall 1 — MOPA frequency and Q-pulse width

### Why you want it

MOPA's whole point over a Q-switched fiber laser is independently controllable **pulse width**
and **repetition rate**. That is what gives you colour marking on stainless, controlled heat
input on brass, and clean deep relief without slag. Without it a 100 W MOPA behaves like an
expensive ordinary fiber laser.

### Why LightBurn can't give it to you here

LightBurn *does* support these parameters — thoroughly. In the Cut Settings Editor it exposes
**Frequency** (kHz) and **Q-Pulse Width** (ns), and in galvo Device Settings **Enable Q-Pulse
Width Setting**, **Fiber Type**, **MO Enabled ONLY When Running**, **Open MO Delay**, **UV Min
Pulse**, **UV Max Pulse**.

**Every one of those is a galvo-device-class field.** On a device typed `"Name": "GRBL"`,
LightBurn's cut settings are speed, power, passes, interval, and the ordinary GCode set. There
is no frequency field and no pulse-width field, because GRBL has no concept of them.

So the limitation is structural: it is not that WeCreat forgot to ship a profile, it is that the
device class LightBurn talks to this machine with does not carry these parameters.

### What might still be possible

1. **A WeCreat M-code for pulse width.** If MakeIt can set it, the controller accepts it somehow.
   A Stage 5 differential capture — same job, two pulse widths, diff the G-code — will reveal
   whether such a code exists. **This is the single highest-value experiment in the project for
   MOPA owners.**
2. **If it exists**, it can be delivered as per-layer custom G-code or as macros. Every discrete
   pulse-width/frequency combination becomes a named macro. Clumsy, but workable — and it would
   let you build a real material library.
3. **If it doesn't exist**, MOPA parameter work stays in MakeIt, and LightBurn is useful for the
   Ultra as a layout/vector/fill tool at fixed source settings.

**Current status: no such M-code has ever surfaced publicly, for any WeCreat machine.** Unknown,
not impossible.

---

## Wall 2 — K9 crystal internal engraving

### What it needs

Internal 3D engraving is not surface marking with a different field size. It requires
coordinated X/Y galvo position, **Z focal depth**, pulse energy, point timing, and layer
sequencing to place discrete fracture points inside a volume. WeCreat describes proprietary
volumetric depth mapping and adaptive focal control.

### Why LightBurn can't do it here

Two independent blocks:

1. **LightBurn's 3D / depth-map engraving is galvo-class.** *3D Sliced Image Mode*, 16-bit depth
   maps, 256+ pass cleanup — all galvo-only. This is confirmed by failure on the actual Lumos:
   an owner with **LightBurn Pro** reported depth-map images simply do not work, and the
   community explanation is exact — *"it uses GRBL, so it works with the core version...
   it's not a real galvo control laser and can't use depth map due to that."*
2. **Even with depth maps, internal engraving is a different operation.** A depth map drives a
   *surface* Z. Internal engraving drives a *focal plane sweep inside a transparent solid*.
   LightBurn has no model for the latter.

MakeIt exposes `crystal-mode` and `crystal-mode3D` as two distinct modes, and accepts STL / PLY /
OBJ / GLB input for them — a 3D-mesh pipeline LightBurn does not have.

### The consolation prizes

- **2D internal marking** (`crystal-mode`, not `crystal-mode3D`) is a simpler operation and might
  be reachable. Untested.
- **Ordinary surface marking through the green lens** at 70 × 70 mm should work fine, giving you
  a fine-detail small-field UV profile. That alone justifies shipping the green profile.

Both are Stage 11.

---

## Wall 3 (bonus) — relief / emboss

`emboss-mode` is in MakeIt's Ultra mode list, and it fails for exactly the same reason as K9 3D:
LightBurn's depth-map engraving is galvo-class and confirmed non-functional on this controller
family.

For anyone doing 16-bit depth-map relief work — brass coin blanks and the like — **that work
stays in MakeIt for now**, or moves to a bridge that uploads a controller-native job.

---

## How to falsify all of this

Every claim above rests on one inference: *the Ultra behaves like the Lumos*. If Stage 0 shows
the Ultra enumerating as a **JCZ/BJJCZ galvo board**, then LightBurn's entire galvo feature set —
Q-pulse width, frequency, lens correction, split marking, 3D depth maps — becomes available and
this document is wrong in the best possible way.

That is a two-minute test. Please run it.
