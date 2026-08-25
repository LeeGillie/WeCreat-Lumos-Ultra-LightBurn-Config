# 15 — Viewing windows and camera filters

Contributed hardware note. Not required to run the machine; useful if you want to *watch* it run,
or point a camera at it, without cooking your eyes or your sensor.

## The problem this solves

The Lumos Ultra has two sources at opposite ends of the spectrum:

| Source | Wavelength | Region |
|---|---|---|
| UV (purple + green lenses) | 355 nm | ultraviolet |
| MOPA fiber (red lens) | 1064 nm | near infrared |

Both wavelengths are **CONFIRMED-hardware** — engraved on the lenses themselves, not inferred
([docs/06](06-modes-and-lenses.md)). That matters here: a filter selection is only as good as the
wavelengths you fed into it.

Both are invisible. Ordinary IR laser goggles are transparent to UV, and UV goggles are
transparent to 1064 nm — which is why `SAFETY.md` insists you match eyewear to the *active source*
rather than to the machine.

For a fixed **window** — an enclosure panel, or a filter in front of a camera — that
source-switching dance is impractical. You want one piece of material that blocks both.

## One material that covers both

**Kentek ACR-A5151G**, a green laser-safety viewing window in 3.2 mm (0.125 in) acrylic with a
30 % impact modifier. Vendor specification, confirmed against the product label:

| Band | Optical density | Relevance to the Ultra |
|---|---|---|
| 200–400 nm | **OD 7** | covers the **355 nm UV** source |
| 850–1100 nm | **OD 7** | covers the **1064 nm MOPA fiber** source |
| 9000–10600 nm | OD 5 | CO₂ — the Ultra has no CO₂ source |
| visible | VLT 50 % | you can still see the work |

Stated compliance: ANSI Z136, CE **EN 12254**, CE **EN 60825-4**, UKCA, REACH, RoHS.

**Both Ultra sources land squarely inside an OD 7 band, with room to spare on either edge** —
355 nm sits mid-band in 200–400, and 1064 nm sits mid-band in 850–1100. Neither is near a rolloff.
That is an unusually clean fit for a machine with this particular pair of wavelengths.

## Read this before you rely on it

Four limits, none of which the OD number tells you.

**1. This is a guard, not eyewear.** EN 12254 covers *screens for laser working places* and
EN 60825-4 covers *laser guards*. Eyewear is certified under **EN 207 / EN 208**, which this
product is not. It is the right standard for a window or an enclosure panel and the wrong one for
something you put on your face. It does not replace your goggles.

**2. OD is attenuation, not survivability.** Optical density tells you how much light gets
through. It says nothing about how long the material lasts under a *direct focused beam*. This is
3 mm acrylic; a focused 60–100 W fiber beam will burn through it. Treat it as protection against
**scattered and diffusely reflected** light — which is the real hazard when a lid is open or a
camera is looking in — and never as a beam stop.

**3. The visible gap is intentional and worth knowing about.** Between roughly 400 and 850 nm the
material is a 50 % neutral-ish green filter, not a blocker. That is deliberate — it is how you see
the work — and it means the **red aiming pointer passes straight through**. Fine, since the
pointer is a low-power alignment diode, but do not read "OD 7" as "blocks everything".

**4. Acrylic and UV.** The 200–400 nm OD 7 comes largely from the acrylic absorbing UV, which is
also what degrades acrylic over time. With a 6 W source and scattered light only this should be
slow, but inspect periodically for yellowing, hazing or crazing and replace when it appears.
Damage in a safety filter is not cosmetic.

## Camera protection

The application this note came from: a filter disc cut from ACR-A5151G, mounted in a vintage
**Kodak Series VI** filter ring and adapter, fitted over a small action camera used to film the
machine working.

Sensible for a reason people underestimate — **camera sensors are damaged far more easily than
eyes are.** There is no blink reflex and no aversion response, the optics concentrate whatever
arrives onto a few square millimetres of silicon, and a sensor will happily stare at a specular
1064 nm glint off a metal workpiece until pixels die. That damage is permanent and usually shows
up as a line or a cluster of hot pixels rather than an obvious burn.

Practical notes if you copy this:

- **VLT 50 %** costs you about one stop. Expect to open up or raise ISO.
- **Strong green cast.** Set a custom white balance through the filter, or fix it in post.
- **Series-mount rings are a good match** for small cameras. They are cheap, plentiful secondhand,
  and clamp a flat disc without needing threads cut into the filter itself.
- Keep the filter clean. A fingerprint on a safety filter is a scattering site.

## Sourcing

Kentek sells the stock size and a custom-cut option
([ACR-A5151G](https://www.kenteklaserstore.com/acr-a5151g-laser-safety-window),
[custom size](https://www.kenteklaserstore.com/acr-a5151g-x-laser-safety-window-custom-size)),
and publishes a
[window filter selection tool](https://www.kenteklaserstore.com/products/window-safety/window-filter-selection)
if you want to check other materials against 355 nm and 1064 nm yourself.

## Status

**Evidence grade: CONFIRMED-vendor** for the filter specification — vendor datasheet and the
physical product label agree.

**Not verified by this project:** that OD 7 is sufficient for any particular exposure scenario on
your machine. That is a determination for whoever is responsible for laser safety where the machine
lives, using the actual accessible power, beam geometry and exposure duration. This document
records what the filter is rated for and how those ratings line up with the Ultra's two
wavelengths. It is not a safety certification and nobody here is your laser safety officer.
