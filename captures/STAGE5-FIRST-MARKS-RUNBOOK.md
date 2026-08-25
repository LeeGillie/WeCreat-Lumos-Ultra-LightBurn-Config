# First marks — runbook ⚠️ BEAM

Open on benchy at
`\\cortex\D\DevHome\WeCreat Lumos Ultra Lightburn Config\captures\STAGE5-FIRST-MARKS-RUNBOOK.md`

**This is the first time this project fires the source.** Everything up to now has been read-only
probing, framing and pointer work. Read the safety block properly — then most of what follows is
just measurement.

Roadmap items closed by this session: **3** (first marks), the definitive half of **Test 3**
(scale), and the confirming run for **1** (`err:20`).

---

## ⚠️ Safety — the parts that actually matter here

| | |
|---|---|
| **Goggles** | **800–1100 nm.** The UV pair protects you from *nothing* at 1064 nm. Confirmed wavelength — it is engraved on the red lens |
| **Reflection** | 1064 nm off metal is **highly specular**. The reflection carries the same hazard as the beam. Secure the workpiece so it cannot shift or tip |
| **Lid** | The interlock is enforced by the controller. We are on the serial path, so it should apply — but treat the lid as closed-and-meant-it, not as a safety system |
| **Exhaust** | Running. Marking metal produces fine particulate |
| **Attendance** | Do not walk away from a running job. Not once, not for the short ones |
| **Camera** | Phone camera is for the **focus dots with the source idle**. Not during marking — sensors have no blink reflex ([docs/06](../docs/06-modes-and-lenses.md)) |

**Stop immediately if:** anything smells wrong, the workpiece moves, you see light that is not the
red pointer, or the machine alarms.

---

## Pre-flight

1. **MakeIt closed.** Power-cycle the Lumos if MakeIt has touched the port since last boot
   ([control-mode latch](control-mode-latch-benchy.md))
2. Red lens fitted — `H SL-1064-200-F290-D10-C`
3. **Metal on the bed, flat and secured.** Black anodized aluminium for preference
4. Lid closed, exhaust on, **goggles on**
5. LightBurn → COM7 → confirm `[WeCreat Lumos :ver 000240]` and **Found WeCreat Device**
6. Device: **WeCreat Lumos Ultra - MOPA 100W Red 210**

## Focus

Manual, by knob. Turn until the **red dots converge to a single point** on the workpiece surface.
Use the phone camera to judge it — the merge point is much easier to call on a screen.

Get this right before anything else. On a galvo, focus sets the **scale of the entire field**, not
just sharpness. Every measurement below is meaningless at the wrong height.

```
Focus set?  yes / no        Material: ....................  thickness ....... mm
```

---

## Where the starting numbers come from

Not guesses — **MakeIt's own marking preamble**, captured off the controller
([Stage 5](stage5-framing-mopa-benchy.md)):

```gcode
M4S1000          <- dynamic power mode, S_Scale 1000 confirmed
G0F15000         <- rapid   15,000 mm/min = 250 mm/s
G1F12000         <- MARKING 12,000 mm/min = 200 mm/s
M38F48           <- frequency 48
M39P200          <- pulse width 200
```

**`F12000` is the vendor's own marking feed rate.** That is our anchor. Power is the unknown —
MakeIt's captures were all framing jobs at `S0`, so no vendor power figure exists.

Set LightBurn's layer speed in **mm/min** to match (`Control Units: mm/min` is already set).

---

## Test A — does it mark at all? *(start low)*

A 10 mm square, **outline only**, centred.

1. Draw a 10 mm square. Anchor **centre**, XPos **105**, YPos **105**
2. Layer mode **Line**
3. **Speed 12000 mm/min**, **Power Max 15 %**
4. Air assist: leave **off**
5. **Frame first** — confirm the pointer traces where you expect on the metal
6. **Start**

| Result | Do this |
|---|---|
| Clear mark | Good. Go to Test B |
| Faint or nothing | Raise power in steps: 15 → 25 → 40 %. Re-run each time |
| Deep gouge / burn-through / heavy sparking | **Stop.** Drop to 8 %, and halve it again if needed |

```
Power that first marked cleanly: ....... %      at 12000 mm/min
```

> **Why 15 %?** On a 60–100 W source, anodized aluminium marks well below a quarter power. Starting
> low costs one extra run; starting high costs the workpiece and tells you nothing about the floor.

## Test B — count `err:20` on a live marking run

While Test A runs, **watch the console**.

```
err:20 count on a marking run:  .......
Did the job complete and mark correctly anyway?   yes / no
```

Expected: **2**, from `M8`/`M9` ([analysis](stage4-airassist-differential.md)). Air assist off
does not remove them — it emits `M9` twice.

- **2 errors and a correct mark** → item 1 closes. Cosmetic, documented, done.
- **More than 2, or the stream aborts** → stop and tell me. Something else is being rejected.

---

## Test C — scale, definitively ⭐

**This is the measurement Test 3 could never make.** A marked square is a physical object. Calipers
work on physical objects; they do not work on light.

1. Square to **100 × 100 mm**, anchor **centre**, XPos **105**, YPos **105**
2. Same speed, the power from Test A
3. Mark it
4. **Measure with calipers**, outside-to-outside on each side

```
Commanded 100.00 mm
Measured  X (top) ......... mm     X (bottom) ......... mm
Measured  Y (left) ........ mm     Y (right) ......... mm
Diagonals ......... mm / ......... mm     (equal = square, not a parallelogram)
```

Also check **placement**: is the square where the screen said it would be, in the right corner
orientation? That is Stage 4's origin result, verified with the beam instead of the pointer.

And check the **corners for sharpness** — rounded or dragged corners mean the galvo is being asked
to turn faster than it can, which is a speed problem, not a power one.

## Test D — Material Test grid

`Laser Tools → Material Test`. This is the efficient way to map the parameter space in one job.

Suggested sweep for a first pass:

| Axis | From | To | Steps |
|---|---|---|---|
| **Power** | 5 % | 50 % | 10 |
| **Speed** | 3000 mm/min | 30000 mm/min | 6 |

Keep cells small (6–8 mm) so the grid fits your scrap. Photograph the result — it becomes the
starting material library for the published profiles, and **only values actually run go in it.**

```
Best-looking cell:  ....... % at ....... mm/min
Range that marks:   ....... to ....... %
```

## Test E — grab `prefs.ini` *(no beam, 2 min)*

Last thing, once LightBurn is closed:

1. Close LightBurn — it writes `prefs.ini` on exit
2. Win+R → `\\cortex\D\lumos.cmd`
3. Press **`p`**, then **`q`**

That gives the generator the real stored values instead of inferred ones.

---

## Results

```
Date:         2026-08-..
Material:     ..........................  thickness ....... mm
Focus:        converged / uncertain

A  first clean mark at ....... %  /  12000 mm/min
B  err:20 count ......   job completed and marked correctly?  yes / no
C  100 mm commanded -> measured  X ......... Y .........
   placement matches screen?  yes / no     corners sharp?  yes / no
D  usable power range ....... to ....... %   best ....... % at ....... mm/min
E  prefs.ini captured?  yes / no

Anything surprising:
....................................................................
```

## What this unlocks

- **A** and **D** give the material library that item 5 needs to ship
- **C** closes scale, the last open geometry question
- **B** closes `err:20`
- **E** lets the profile generator emit verified values

After this, the only thing between the project and publishing is **item 4** — confirming
`M38F`/`M39P` survive being emitted from LightBurn's per-layer custom G-code
([docs/14](../docs/14-mopa-parameters-in-lightburn.md)) — and then packaging.
