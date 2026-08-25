# Stage 3 — `err:20` diagnosis from LightBurn's saved G-code

- **Machine:** WeCreat Lumos Ultra, 60W MOPA fiber, red lens
- **Host:** benchy (USB, COM7)
- **LightBurn:** 2.1.04, Custom GCode profile
- **Date:** 2026-08-24
- **Evidence grade:** CONFIRMED-hardware (file is LightBurn's own output)

## What LightBurn actually emits

Full job, 10 mm square, saved via Laser window -> Save GCode:

```gcode
;LightBurn Core 2.1.04
;Custom GCode device profile, absolute coords
;Bounds: X97 Y100 to X107 Y110
G00 G17 G40
G21;Restore metric mode
G54

G90;Restore absolute mode
M4
;Cut @ 636.524 mm/min, 90% power

M8
G0 X107Y100
;Layer VirtArray
G1 Y110S900F636.52
G1 X97
G1 Y100
G1 X107
M9
M5
G90;Restore absolute mode
M2
```

## Vocabulary diff against MakeIt's known-good preamble

MakeIt only ever uses: `G0 G1 G4 G90` plus its private `M`-codes.
It never emits `G17`, `G40`, `G21`, `G54`, `M8`, `M9`, `M2`.

| Word | In MakeIt? | GRBL-standard? | Suspect |
|---|---|---|---|
| `G00 G17 G40` | no | yes | **HIGH** — plane select + cutter comp are commonly stripped from minimal GRBL builds |
| `G21` | no | yes | medium — machine is metric-native, may be a no-op |
| `G54` | no | yes | **HIGH** — WCS table often omitted; WeCreat uses `M107X..Y..` for origin instead |
| `M8` / `M9` | no | yes (air assist) | medium — two lines, would give 2 more errors |
| `M5` | no | yes | low — `M4`/`M5` pair is core GRBL |
| `M2` | no | yes | low |

Exactly **two** `err:20` responses were observed. Two rejected *lines*
(not two rejected words — a whole line fails as one). That points at two of
`G00 G17 G40`, `G21`, `G54`. If `M8`/`M9` were also rejected the count
would have been four.

Leading hypothesis: **`G00 G17 G40` and `G54`.**

## Why this is probably not fatal

GRBL reports `error:20` and **continues to the next line**. It does not abort
the stream. All three suspect lines are modal-state setup:

- `G17` XY plane — the only plane a galvo/gantry laser has anyway
- `G40` cancel cutter compensation — never enabled
- `G54` work coordinate system 1 — the default WCS
- `G21` metric — the machine's native unit

Discarding any of them leaves the machine in the state LightBurn intended.
`G0`, `G1`, `M4`, `M5`, `S` and `F` — everything that actually moves the head
or fires the source — are untouched.

**Working conclusion: `err:20` x2 is cosmetic noise, not a blocker.**
This must still be confirmed by watching a framing pass actually track the
square (Stage 4), because "no abort" is not the same as "correct output".

## Confirmation procedure (beam-free, ~5 min)

LightBurn -> Laser window -> **Console** tab. Type each line, press Enter,
record the reply. None of these move the head or fire the source.

| # | Send | Expect if supported | Records |
|---|---|---|---|
| 1 | `G17` | `ok` | |
| 2 | `G40` | `ok` | |
| 3 | `G21` | `ok` | |
| 4 | `G54` | `ok` | |
| 5 | `M8` | `ok` (air pump may audibly start) | |
| 6 | `M9` | `ok` (air pump stops) | |
| 7 | `M5` | `ok` | |

Two of lines 1-4 are expected to answer `error:20`.

> **Do not** send arbitrary `M`-codes beyond this list. WeCreat renumbers its
> private M-code space per machine model — see `docs/04-mcode-dictionary.md`.

## If the offenders cannot be suppressed

LightBurn hardcodes the `G00 G17 G40` / `G21` / `G54` block for all GCode-class
devices. There is no device-setting checkbox that removes it, and Start G-code
is appended *after* it. Options, in order of preference:

1. **Accept it** — if Stage 4 framing is accurate, the errors are noise.
   Document them in the README so users are not alarmed.
2. Per-layer / device Start G-code cannot help; it only adds.
3. A post-processor or a serial shim that filters the three lines. Heavy;
   only justified if the controller turns out to abort rather than continue.

## Status

- Two rejected lines identified by elimination, pending console confirmation
- Reclassified from **BLOCKER** to **cosmetic, pending Stage 4**
- Next action is Stage 4 framing, which was previously gated on this
