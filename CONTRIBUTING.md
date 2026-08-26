# Contributing

Thank you — this project cannot succeed without people who own the machine. It was built by one
person with one Lumos Ultra, and most of what would help most now needs someone *else's* hardware.

**Read [SAFETY.md](SAFETY.md) first.** It is short and it is not boilerplate. Two things in it are
actively counter-intuitive:

- **Frame can fire the beam.** LightBurn's framing G-code carries no power term and inherits the
  modal `S` from the previous job. Every gantry-laser habit says framing is safe. Here it is not.
- **Goggles differ by lens.** Purple and green are 355 nm UV. Red is 1064 nm — confirmed, engraved
  on the glass. One pair does not cover both.

---

## The one rule that makes this project different

**Every claim carries an evidence grade, and we never upgrade a grade to be helpful.**

| Grade | Means |
|---|---|
| `CONFIRMED-vendor` | WeCreat's or LightBurn's own artifact says so — a shipped file, their output, their UI |
| `CONFIRMED-hardware` | Observed directly on a physical machine |
| `CONFIRMED-community` | An owner observed it and reported how |
| `INFERRED` | Reasoned from adjacent confirmed facts. Say so |
| `UNKNOWN` | We have the thing but not its meaning |

An honest `UNKNOWN` is a contribution. A confident guess dressed as fact is a hazard — someone
downstream will point a 100 W fiber laser at something based on it.

**"I sent it and nothing bad happened" is not evidence of meaning.** Absence of an observed effect
is not a definition.

Where this project got something wrong, **the error is left in place with the correction beside
it** — see [`captures/stage4-which-device-are-we-testing.md`](captures/stage4-which-device-are-we-testing.md).
That is deliberate. The reasoning is often more useful than the answer.

---

## The four questions that would help most

### 1. ⭐ Do Vision / Lumos / Vista owners see the same stalls?

**The single most valuable contribution available, and it needs a machine this project does not
have.**

The Ultra stalls mid-job because the controller's status report is a stub: it answers `Idle` with
zero feed **even while executing a job, and even when told to feed-hold**
([evidence](captures/stage5-streaming-stalls.md)). LightBurn cannot pace a stream against
telemetry that lies.

WeCreat publishes official LightBurn configs for **Vision, Vision Pro, Vista and Lumos** — but not
the Ultra. So:

- If those machines **stall the same way**, this is a family-wide firmware trait and the missing
  Ultra config is probably unrelated.
- If they **run clean**, something regressed in the Ultra, and that changes what everyone should
  be asking WeCreat for.

**How to help:** run a dense fill from LightBurn on any WeCreat machine using the official config.
Does it finish without stalling? Type `?` in the Console mid-job — does the state field *ever* read
anything but `Idle`? **Open an issue with the answer either way.** A clean run is as informative as
a broken one.

### 2. Does a lower baud rate help?

Everything runs at **1,000,000 baud**, inherited from WeCreat's Lumos profile. The obvious defence —
"MakeIt works fine over the same cable" — does not hold: **MakeIt does not use the serial port for
job data.** It uploads over the machine's USB network gadget
([why](captures/stage5-stall-analysis-round2.md)). The serial link has never actually been shown
reliable at 1 Mbaud.

**How to help:** does the controller accept a lower rate? Do the stalls change?

### 3. Is the CH340 re-enumerating?

On one machine the serial bridge moved from `COM6` to `COM9` between sessions. If it re-enumerates
spontaneously, that sits underneath everything else here.

**How to help:** Device Manager → *Show hidden devices* → count ghost CH340 entries, and watch
whether the port number changes across power cycles.

### 4. An upload bridge over `192.168.42.1`

MakeIt uploads jobs to the controller's SD card over HTTP on the machine's private USB network and
lets the controller run them locally — a path that never touches the acknowledgement protocol that
is failing. A tool doing the same with LightBurn's saved G-code would sidestep the streaming
problem entirely.

Software project, not a config change. Endpoint map: [docs/05-connectivity.md](docs/05-connectivity.md).

---

## Also wanted

- **Any accessory at all.** Rotary Pro, slide extension, AutoFlow conveyor — all three profiles are
  marked SPECULATIVE and none has been near hardware
- **Green lens / K9 crystal.** 2D surface work through it is untested
- **Camera lens calibration and workspace alignment.** The camera connects via LightBurn's built-in
  WeCreat preset; alignment is not done
- **`Enable Q-Pulse Options`.** This toggle exists on the Custom GCode device class. If it exposes a
  per-layer pulse-width control, MOPA pulse width becomes a first-class LightBurn parameter and
  [docs/09](docs/09-k9-and-mopa-limits.md) needs rewriting
- **The 11 unknown M-codes** in [docs/04](docs/04-mcode-dictionary.md)
- **60 W machines.** Everything here was done on a 100 W
- **Material settings that you have actually run.** Only measured values go in the library

## Practical notes

- Profiles are **generated**. Edit `tools/profile-spec.json`, run `tools/build-profiles.ps1`, and
  make sure `tools/validate-lbdev.ps1` passes. Do not hand-edit `profiles/draft/*.lbdev`.
- Captures go in `captures/` with machine, date, contributor and evidence grade at the top.
- **Identify a LightBurn device by the `;` header line of its emitted G-code, never by its
  DisplayName.** Two device classes here can share a name — that mistake cost this project an
  afternoon, and it is written up rather than hidden.
