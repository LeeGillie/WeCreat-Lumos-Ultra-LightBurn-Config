# Community report #1 — Lumos Flex, LightBurn's WeCreat-flavor warning

**Date:** 2026-08-27 · **Machine:** WeCreat **Lumos Flex** · **LightBurn:** 2.1.x
**Contributor:** **Chris Zambesi** — first community data point this project has received, offered
unprompted within hours of publication. Thank you.
**Evidence grade:** CONFIRMED-community

## What was reported

On connecting a **Lumos Flex**, LightBurn showed:

> *"Your laser has been detected as a WeCreat device but you are not using a custom gcode device
> with the WeCreat device flavor. The device may not work correctly as a result."*

## Why this matters

**It confirms three things this project had inferred, on a machine we do not own.**

### 1. LightBurn detects WeCreat machines from the banner, independent of device class

The warning fires because LightBurn recognised a WeCreat controller on the port while the selected
device profile was *not* Custom GCode with the WeCreat flavor.

This is the same conclusion reached on the Ultra
([capture](stage4-which-device-are-we-testing.md)) — detection comes from the controller's
identification string, not from anything in the profile. Now observed on a second model.

### 2. `Custom GCode` + `GCodeFlavor: wecreat` is the class LightBurn itself wants

The project chose that class by reasoning, then briefly doubted it. **LightBurn now says so
directly, in a warning dialog, unprompted.** That is about as strong a confirmation as a device-class
decision can get.

### 3. WeCreat's official configs predate the WeCreat flavor

`docs/04` already noted that WeCreat's own `WeCreat-Lumos-v1.5.lbdev` declares `"Name": "GRBL"` and
would therefore trigger this warning. **Confirmed in the wild** — an owner using an official config
hit exactly that.

So the warning is not a fault. It is LightBurn reporting that the vendor's shipped configuration is
out of date relative to its own WeCreat support.

## Lumos Flex specifications, for the record

From WeCreat's product page, checked 2026-08-27:

| | |
|---|---|
| Working area | **116 × 116 mm** (520 × 116 mm with Slide Extension) |
| Sources | **15 W fiber + 15 W diode** |
| Lens changing | **None** — sources switch in software |
| Max speed | 10,000 mm/s |
| Spot | fiber 0.03 × 0.03 mm · diode 0.08 × 0.06 mm |

**The Flex field is 116 × 116 — the same as the base Lumos.** So WeCreat's official *Lumos* config
is a reasonable dimensional starting point for a Flex. The workspace trap this project warns about
is **Ultra-specific**: only the Ultra is 210 × 210 and therefore silently mis-sized by that file.

## 🎯 This reshapes the family picture

WeCreat's Lumos profile carries macro labels `M18S0` = **"1064red"** and `M18S1` = **"455Blue"** —
a fiber source plus a **blue diode**. The Flex is 15 W fiber + 15 W diode at 116 × 116 mm.

| | Lumos | Lumos Flex | **Lumos Ultra** |
|---|---|---|---|
| Field | 116 × 116 | 116 × 116 | **210 × 210** |
| Second source | 455 nm blue diode | diode | **355 nm UV** |
| Fiber | fiber | 15 W fiber | **60/100 W MOPA** |
| Lens changing | — | none | **three field lenses** |
| Official LightBurn config | ✅ | ❌ | ❌ |

**The Lumos and Flex look like close relatives; the Ultra is the outlier** — bigger field, a UV
source in place of the blue diode, MOPA in place of plain fiber, and interchangeable optics.

That strengthens the case that the Ultra's firmware is the newer and least-exercised of the family,
which is the leading explanation for the streaming defect
([analysis](stage5-streaming-stalls.md)).

## The fill test — run 2026-08-27

Chris was asked whether a dense fill would stall on his Flex. He ran it and reported:

> *"did a 90x90mm fill box with the diode on the flex - no issues in lightburn"*

**A 90 × 90 mm fill completed on a Lumos Flex, from LightBurn, with no stall.**

### ⚠️ Not yet a controlled comparison — one large confound

**The Flex was marking with its diode source.** The stall mechanism is buffer starvation: the
machine consumes moves faster than a 1,000,000-baud link can deliver them, which is why a
LightBurn developer described a galvo as *"running dry very quickly"* at a 127-byte buffer.

Diode marking runs far slower than 100 W MOPA. A slow job may simply never empty the buffer.

So this result is consistent with **either** of two very different explanations, and does not yet
distinguish them:

| Explanation | Would also produce this result? |
|---|---|
| The Flex firmware does not have the defect | Yes |
| The diode job never ran fast enough to starve the stream | **Also yes** |

**Grade: CONFIRMED-community that the job completed. UNRESOLVED as to why.**

### What would settle it

Two numbers, both easy for Chris to read off his own LightBurn:

1. **Speed.** The Ultra fills that fail here run at **12000 mm/min**. If the diode ran at a few
   hundred, the comparison is not like-for-like.
2. **Fill type.** Plain *Fill* emits **99.97 %** of its moves in `G91` relative mode; *Offset Fill*
   only 8.6 % ([evidence](stage5-G91-relative-mode-CONFIRMED.md)). The exposure differs by more
   than a factor of ten.

Asked on 2026-08-27; awaiting reply.

### The pattern this now belongs to

Two independent reports of the same class of job running clean on machines that are **not** this
one:

| Machine | Source | Result |
|---|---|---|
| Lee's Lumos Ultra, firmware `ver 000240` | 100 W MOPA @ 12000 mm/min | **stalls and drifts** |
| LightBurn dev team's Ultra | not stated — *possibly unreleased firmware* | clean |
| Chris Zambesi's Lumos Flex | diode, speed not yet known | clean |

That shifts weight — carefully, not conclusively — away from *family-wide defect* and toward
*this machine, this firmware, or this speed*. It also raises the value of the firmware version
string a LightBurn developer offered to supply.

**Do not over-read it.** Neither clean run is yet a matched comparison against a failing one.

## Guidance given

- Clear the warning: Device Settings → Custom GCode tab → **GCode Flavor: WeCreat**, or create the
  device as Custom GCode rather than GRBL
- **Use 116 × 116 mm** for a Flex, not the Ultra's 210 × 210
- Flagged as *assumptions, not findings*, since they come from an Ultra: `M18` source select may be
  required in the **User Start Script**; air assist off (`M8` is rejected); and **Frame can fire the
  beam**
