# FIRST MARK ✅ — and the beam fires during rapid travel

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **Lens:** red / MOPA
**Material:** black anodized card · **Contributor:** Lee Gillie
**Evidence grade:** CONFIRMED-hardware

## The milestone

**A 20 mm square, marked from LightBurn, at 15 % power / 12000 mm/min.** Clean, well-defined,
correct size and position. The first mark this project has ever produced.

Anodized aluminium marks at **15 %** — the "start low" instinct was right, and the real floor is
probably lower still.

## The defect: a dotted trail from field centre to the job's start corner

Visible in the photograph: a line of discrete dots running from the **centre of the field** to the
**upper-right corner of the square**.

That path is the job's **first rapid**. The galvo parks at `MPos 0,0` — which is field centre — and
the job's first instruction is `G0 X115Y95`, out to the start corner. **The beam is on during that
G0.**

**Why dotted rather than solid:** the source is pulsed. At the 200 mm/s marking feed the pulses
overlap into a continuous line; at rapid speed they separate into individual dots. The dot spacing
is a direct readout of pulse rate against travel speed.

## Diagnosis: GRBL laser mode is not in effect

In standard GRBL, `$32=1` selects **laser mode**, which does two things:

1. The laser is **off during `G0` rapids**
2. `M4` becomes **dynamic power**, scaling output with feed rate

With `$32=0` the controller is in spindle mode: once `M3`/`M4` sets a power, the output stays on
continuously — **including through rapids**. That is precisely the observed behaviour.

LightBurn emits a bare `M4` early, then rapids to the start corner:

```gcode
M4                <- laser mode on, power modal
;Cut @ 636.524 mm/min, 90% power
M8
G0 X115Y95        <- RAPID. Beam should be off here. It is not.
G1 Y115S900F636.52
```

### Corroboration from MakeIt

MakeIt's own marking preamble **positions first and enables the source second**:

```gcode
G90  G4P1  M46A1B0  G0X105Y105     <- move to centre FIRST
M25S1  M26S1  M24S15  M15S70  M59A-1000B50
M1S0  M4S1000                       <- laser mode enabled AFTER positioning
M11S0.08
G0Z47.8  M38F48  M39P200
G0F15000  G1F12000
```

The vendor sidesteps the problem by ordering, never issuing a rapid while the source is armed.
**LightBurn cannot be made to reorder its own output**, so ordering is not a fix available to us —
we need the firmware to respect laser mode.

### The test

Console, in order:

```
$32=1        <- enable laser mode
$32          <- read it back
```

Then re-run the square. **Success = no dotted trail.**

`$` returned a bare `ok` in earlier probing rather than an error, so the parser accepts `$`
commands even though `$$` returns nothing useful. If `$32=1` is rejected, laser mode is not
implemented and this becomes a documented limitation rather than a setting.

## Second finding: `M18S0` does not persist

Sequence observed:

1. Frame — fine, no cutting
2. **Start — nothing happened**
3. Send `M18S0` — **the fan audibly starts**
4. Start — marks correctly

`M18S0` had already been sent earlier in the session. So something between then and now cleared it
— almost certainly the **`\x18` soft reset** LightBurn issues on Stop
([capture](stage4-mirror-origin-benchy.md)).

**Consequence: source select cannot be a one-off console command.** It must go in the profile's
**device Start G-code** so every job re-asserts it.

Also newly learned: **`M18` starts the exhaust fan**, so it is doing more than selecting an optical
path — it is a source-power/enable command.

## Status

| | |
|---|---|
| First mark | ✅ 15 % @ 12000 mm/min on black anodized |
| Geometry, placement, definition | ✅ correct |
| Beam on during rapids | 🔴 **defect — travel scars on every job** |
| `M18S0` in Start G-code | 🟡 required, not yet implemented in the generator |
| `err:20` count on this run | ❓ not yet reported |
