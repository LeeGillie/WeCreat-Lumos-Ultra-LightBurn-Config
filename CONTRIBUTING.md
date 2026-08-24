# Contributing

Thank you — this project cannot succeed without people who own the machine.

**Read [SAFETY.md](SAFETY.md) first.** It is short and it is not boilerplate.

---

## The one rule that makes this project different

**Every claim carries an evidence grade, and we never upgrade a grade to be helpful.**

| Grade | Means |
|---|---|
| `CONFIRMED-vendor` | WeCreat's own artifact says so — a shipped file, a support article, the application bundle |
| `CONFIRMED-community` | Someone observed it on hardware and reported how |
| `INFERRED` | Reasoned from adjacent confirmed facts. Say so |
| `UNKNOWN` | We have the thing but not its meaning |

An honest `UNKNOWN` is a contribution. A confident guess dressed as fact is a hazard — someone
downstream will point a 100 W fiber laser at something based on it.

**We will not accept "I sent it and nothing bad happened" as evidence of meaning.** Absence of an
observed effect is not a definition.

---

## What helps most, in order

### 1. Stage 0 — USB enumeration *(2 minutes, no beam, no laser knowledge needed)*

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1 > ultra-usb.txt
```

Open a **Feature status report** issue and paste the output. This single test settles the
question the entire project's architecture rests on. If you do nothing else, do this.

### 2. Stage 1 — the serial banner and `$$`

No WeCreat machine's `$$` output has ever been published publicly. Yours would be the first.

### 3. Stage 5 — differential MakeIt captures

Run the same job twice, change exactly one variable, diff the G-code. This is how the Ultra's
M-code table gets written, and it involves no experimentation on the machine at all — you are
just watching what MakeIt already does. See
[docs/03-bringup-plan.md](docs/03-bringup-plan.md#stage-5).

### 4. You don't need an Ultra

- Close one of the [known research gaps](docs/evidence/sources.md#known-gaps-in-our-own-research) —
  Reddit, YouTube comments, GitHub code search, **FCC ID filings** (the best route to a
  definitive answer on the controller board).
- Review the docs for anything overstated.
- Improve the tooling, or port the PowerShell scripts to bash.
- Test the profile generator and the `.lbdev` validator.

---

## Issue types

| Type | Use when |
|---|---|
| **Feature status report** | You tested something from the inventory and can move its status |
| **M-code discovery** | You have evidence about what a code does |
| **Profile bug** | A profile in `profiles/` behaves wrongly |
| **Calibration data** | Field size, offsets, mirroring, steps-per-rotation measurements |

Every issue template asks for your machine configuration — source, lens, accessories, MakeIt
version, LightBurn version, firmware banner. Please fill it in; almost every open question here
turns out to be model- or firmware-specific.

## Pull requests

- **Documentation:** grade your claims and cite a source. Add the source to
  `docs/evidence/sources.md`.
- **Profiles:** edit `tools/profile-spec.json` and regenerate with `tools/build-profiles.ps1`.
  Do not hand-edit the generated `.lbdev` files — they will drift.
- **Never commit** anything from `reference/` (it is gitignored), and never commit WeCreat's
  `.lbdev` files, firmware, or extracted application code.
- Profiles must stay clean: no hard-coded `CommPort`, no local paths, unique `GUID`, and
  **empty start/end G-code until verified on hardware.**

## Style

Plain, specific, and unexcited. If a thing does not work, say it does not work and say why.
Nobody is served by an inventory that reads as more complete than it is.

## Reporting a near miss

If something moved unexpectedly, fired unexpectedly, or you sent something you shouldn't have —
please open an issue. A documented near miss is worth more to the next person than a dozen
successful tests, and nobody here will give you a hard time about it.

## Code of conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
