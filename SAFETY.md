# SAFETY

Read this before connecting a Lumos Ultra to anything in this repository.

This project asks people to send commands to a machine containing a **6 W UV laser** and,
optionally, a **60 W or 100 W MOPA fiber laser**. Those are not hobby diode powers. A 100 W
fiber laser will remove metal. It will also destroy an eye faster than a blink reflex, at a
wavelength you cannot see coming.

---

## The rules of this project

1. **No blind M-codes.** Nobody is ever asked to send an undocumented M-code "to see what it
   does." Every code in [docs/04-mcode-dictionary.md](docs/04-mcode-dictionary.md) is graded, and
   the ungraded ones stay unsent. WeCreat renumbers codes between models — an intuition borrowed
   from Marlin, GRBL, or another WeCreat machine is not evidence.

2. **Draft profiles ship inert.** Everything in `profiles/draft/` has **empty start and end
   G-code**, **no macros**, and **Z disabled**. That is deliberate. Candidate start blocks live
   in the documentation, not in the profile, until someone confirms them on hardware.

3. **Beam-free stages first.** [The bring-up plan](docs/03-bringup-plan.md) is ordered so that
   Stages 0–2 involve no beam at all. Most of what this project needs can be learned there.

4. **Lowest survivable power, always.** First marks are at the lowest power and highest speed
   that produce any mark at all, on scrap, with the correct lens confirmed installed.

---

## The control-mode latch — you will hit this

**Opening the machine's USB serial port takes control away from MakeIt, and you get it back only
by power-cycling the machine.** Closing the software is not enough.

The controller cannot tell one serial client from another. LightBurn, PuTTY, or a read-only probe
script all trigger it identically — MakeIt then shows:

> *"Machine is now connected to LightBurn. To restore Make It control… close the LightBurn
> software… after restarting the device, reconnect Make It."*

Nothing is damaged and it is fully reversible, but plan around it:

```
Working in MakeIt     ->  power-cycle first if anything has touched the COM port
Working in LightBurn  ->  close MakeIt first, it holds the port
Switching back        ->  close the client, POWER-CYCLE, reconnect MakeIt
```

This is also the mechanism behind the community's perennial "Port failed to open — already in
use?" and "laser busy" reports. See
[the capture](captures/control-mode-latch-benchy.md).

## ⚠️ Frame can fire the beam — this is not a gantry laser

**Confirmed on hardware, 2026-08-25.** A framing pass **cut a visible line** in a workpiece.

LightBurn's framing G-code for this device carries **no power term and no laser-mode command**:

```gcode
G0 X10Y180
G1 Y200F800      <- G1 is a CUTTING move. No S value anywhere in the job.
```

With no `S` in the job, the controller uses the **modal `S` left over from the previous job**, and
once a source has been selected with `M18`, that is a live beam tracing your frame.

MakeIt never has this problem — its framing geometry states power explicitly:
`G1X90.1Y96.21`**`S0`**. LightBurn omits it and inherits.

> **Treat Frame as a beam operation.** Goggles on, lid closed, workpiece secured — every time.
>
> If a marking job has run, send **`M5`** and **`S0`** in the Console before framing.

Every gantry-laser habit teaches that framing is safe. On this machine that habit is wrong.

## Wavelength-specific hazards

| Source | Wavelength | Notes |
|---|---|---|
| UV | 355 nm | Invisible. Standard laser goggles rated for IR **do not** protect against UV. WeCreat sells 190–550 nm goggles for this |
| MOPA fiber | **1064 nm — confirmed**, engraved on the red lens itself (`H SL-1064-200-F290-D10-C`). WeCreat still does not publish it | Invisible. Highly specular off metal — the reflection is as dangerous as the beam. Needs 800–1100 nm goggles |

**One pair of goggles does not cover both sources.** Check which lens and which source is active
before you close the lid, and wear the matching pair. This is the reason every profile in this
repository carries a start-of-job checklist.

Note that both UV lenses — purple *and* green — run the 355 nm source, confirmed from the glass
itself ([docs/06](docs/06-modes-and-lenses.md)). Only the red lens moves you to 1064 nm. So the
eyewear question is really "which lens is fitted", and there are two answers, not three.

For **fixed windows and camera filters** — where you cannot swap a filter every time the source
changes — dual-band material exists that covers both 355 nm and 1064 nm at OD 7. See
[docs/15](docs/15-viewing-windows-and-camera-filters.md). That is guard-rated material,
**not eyewear**, and does not replace your goggles.

## The interlock caveat — read this one twice

The Lumos-family lid interlock is enforced by the **controller**, not by the software.

The reverse-engineered REST endpoint `POST /test/cmd/mcu` on port 8080 **bypasses it**. The
`weburn` author's own warning, verbatim:

> **WARNING** THIS GCODE WILL RUN REGARDLESS OF THE LID POSITION. Please remember to wear safety
> glasses.

If you experiment with the network path described in
[docs/05-connectivity.md](docs/05-connectivity.md), you are working on a machine whose safety
interlock is not in the loop. Treat the lid as decorative and the goggles as mandatory.

## Network exposure

The Vision-generation controller was found running SSH on port 22 with **root password login
permitted**, and an unauthenticated directory listing of the entire filesystem on port 8082 —
`/etc/shadow` included. Assume the Ultra is no better until someone checks.

**Do not put a WeCreat machine on an untrusted network, and do not port-forward it.** If you need
network access, keep it on the USB RNDIS link or an isolated VLAN.

## Fire

MOPA fiber work on metal is comparatively low-risk for fire. UV work on wood, paper, leather and
coated goods is not. Do not run unattended, keep a CO₂ extinguisher within reach, and remember
that the AutoFlow conveyor exists specifically to run long unattended batches — which is exactly
the situation where an unattended fire becomes a house fire.

## Things this project will not do

- Publish a profile whose start G-code contains unverified M-codes.
- Recommend disabling any interlock or safety feature.
- Accept a contribution whose evidence is "I tried it and nothing broke."
- Pretend a MakeIt-only capability is reachable from LightBurn because it would be nice if it were.

## If something goes wrong

Power off at the wall. Do not reach into the enclosure while the controller is powered — the
galvo head can move without warning if a queued job resumes.

Report it in an issue, including what you sent. A near miss documented here is worth more than a
dozen successful tests.
