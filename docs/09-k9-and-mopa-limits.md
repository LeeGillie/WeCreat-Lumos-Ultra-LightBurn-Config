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

### ✅ RESOLVED 2026-08-24 — this wall is DOWN

**MOPA pulse width and frequency ARE controllable from LightBurn**, via per-layer custom G-code.

Two real MOPA jobs, identical except for the pulse-width setting in MakeIt, produced captures
differing by **exactly one line**:

```diff
- M39P200
+ M39P500
```

```gcode
M38F<kHz>     ; MOPA frequency        CONFIRMED-vendor
M39P<ns>      ; MOPA pulse width      CONFIRMED-vendor
M18S0         ; MOPA source select    CONFIRMED-vendor
```

LightBurn's GRBL device class supports **per-layer custom G-code** — exactly the granularity a
MOPA material library needs. Each layer can carry its own `M38`/`M39` pair.

So the limitation is narrower than it appeared: **LightBurn's galvo-class *UI fields* remain
unavailable, but the underlying capability is not.** You lose the convenient spin-boxes; you keep
the control.

Caveat before building on this: the mapping between MakeIt's UI units and the G-code value has
not been verified, and the accepted ranges are unknown. See
[the capture](../captures/stage5-mopa-pulsewidth-CONFIRMED.md).

The rest of this section documents *why* the native fields are unavailable, which is still
accurate and still worth understanding.

### What remains to establish

1. **Unit mapping.** `P200`/`P500` and `F48`/`F75` are MakeIt's own numbers. Nanoseconds and
   kilohertz are the natural reading and fit typical JPT MOPA ranges, but the relationship between
   MakeIt's UI field and the emitted value is unverified.
2. **Accepted ranges**, so a profile does not offer values the firmware rejects.
3. **Emitting them from LightBurn**, which is untested. The codes are confirmed as *WeCreat's
   output*; sending them *to* the machine ourselves is a separate step.

Until those three are settled the profiles ship without them — this project's rule is that a
profile contains nothing that has not been demonstrated end to end.

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

---

## ⚠️ Correction pending — `Enable Q-Pulse Options` exists on a Custom GCode device

**2026-08-25.** This document states that Q-Pulse Width is gated to LightBurn's galvo device
classes and therefore unreachable for us.

**LightBurn 2.1.04's Device Settings → Custom GCode tab carries an "Enable Q-Pulse Options"
toggle**, on the very Custom GCode device this project uses. It is also present in the prefs as
`EnableQPulse` (currently `false`), and LightBurn's own documentation lists it as *"Fiber laser
pulse control"*.

If enabling it exposes a per-layer Q-pulse width control, then **MOPA pulse width is a first-class
LightBurn parameter here**, not something that has to be smuggled in as per-layer custom G-code —
which would supersede the approach in [docs/14](14-mopa-parameters-in-lightburn.md) and make a
chunk of the argument above wrong.

**Not yet tested.** The section above stands as written until it is, but treat its conclusion as
**suspect rather than settled**. Testing is queued behind the streaming-stall investigation
([capture](../captures/stage5-streaming-stalls.md)).

Source: <https://docs.lightburnsoftware.com/2.1/Reference/DeviceSettings/CustomGCode/>
