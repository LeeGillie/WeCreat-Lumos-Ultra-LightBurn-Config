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

## Still open — the question this could answer

Chris has a Flex on LightBurn. **If he runs a dense fill and it completes**, the stall is
Ultra-specific. **If it stalls too**, the defect is family-wide and the missing Ultra config is
probably unrelated to it.

Either answer moves the project. See [CONTRIBUTING.md](../CONTRIBUTING.md), question 1.

## Guidance given

- Clear the warning: Device Settings → Custom GCode tab → **GCode Flavor: WeCreat**, or create the
  device as Custom GCode rather than GRBL
- **Use 116 × 116 mm** for a Flex, not the Ultra's 210 × 210
- Flagged as *assumptions, not findings*, since they come from an Ultra: `M18` source select may be
  required in the **User Start Script**; air assist off (`M8` is rejected); and **Frame can fire the
  beam**
