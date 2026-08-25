# Air-assist differential — and a correction to the device-class claim

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **LightBurn 2.1.04**
**Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED-hardware

## ❌ Correction: we were on Custom GCode all along

The previous capture concluded, from the device DisplayName, that Stage 4 ran on a GRBL-class
profile. **That was wrong.** Both saved files begin:

```
;LightBurn Core 2.1.04
;Custom GCode device profile, absolute coords
```

**The device is Custom GCode + `GCodeFlavor: wecreat`** — the profile this project recommends.

### How the mistake happened, so it is not repeated

`captures/lightburn-prefs-benchy-20260824-110824.ini` contained **two devices sharing the
DisplayName pattern**: a GRBL one called *"WeCreat Lumos Ultra - MOPA 100W Red 210"* and a Custom
GCode one called *"WeCreat Lumos Ultra - MOPA Red 210"*. Our generator emits the **Custom GCode**
profile under the *100W* name too — so the name is carried by both classes and cannot identify one.

Asking "is the selected device *MOPA 100W Red 210*?" was a question whose answer could not
distinguish the two. The operator answered correctly; the question was faulty.

Today only one WeCreat device remains in the dropdown, and the GRBL duplicate is gone.

### What this restores

| Claim | Status |
|---|---|
| `Custom GCode` + `GCodeFlavor: wecreat` is the right class | **Reinstated.** It is what performed every Stage 4 test |
| `GCodeFlavor: wecreat` drives `Exit_Preview_Mode` / `M41Y1` | **Plausible again.** The earlier retraction was itself based on the faulty identification |
| Stage 4 geometry results | Unaffected. They were always about the machine |

**Lesson: identify a device by the `;` header line of its emitted G-code, not by its DisplayName.**

## The air-assist differential

Same document, same 20 mm square centred at 105,105, same device. One variable.

| | Air **ON** | Air **OFF** |
|---|---|---|
| after `M4` | **`M8`** | **`M9`** |
| before `M5` | `M9` | `M9` |

Complete diff between the two files — one line:

```diff
  M4
  ;Cut @ 636.524 mm/min, 90% power

- M8            <- air ON
+ M9            <- air OFF
  G0 X115Y95
```

> ### Turning air assist OFF does not remove the air commands. It emits `M9` twice.
>
> LightBurn still sends two air-assist M-codes either way. There is no "no air-assist commands"
> state reachable from the layer toggle.

## What this does to the `err:20` diagnosis — it is now clean

Framing and marking ran on the **same device class**, so the comparison is finally single-variable:

| Run | Contains | `err:20` |
|---|---|---|
| Framing | `G00 G17 G40`, `G21`, `G54`, `G0`, `G1` | **0** |
| Marking | all of the above **plus `M4`, `M8`/`M9`, `M5`** | **2** |

That **eliminates** the earlier suspects: `G17`, `G40`, `G21` and `G54` are all present in a
framing run that produced no errors. They are accepted by the firmware.

Remaining candidates, and what we know:

| Code | Verdict |
|---|---|
| `M5` | **Accepted** — returned `ok` in the console log |
| `M4` | Almost certainly accepted — MakeIt's own G-code uses `M4S1000` |
| **`M8` / `M9`** | **The only pair left, and exactly two commands for exactly two errors** |

**`M8`/`M9` is now the supported conclusion, not merely the plausible one.**

## But the obvious fix does not work

Turning air assist off swaps `M8` for `M9` rather than removing it, so both configurations still
emit two air-assist commands and both should still produce two `err:20`.

Options, in order of preference:

1. **Check Device Settings for a device-level air-assist option.** If LightBurn can be told this
   machine has no air assist, it may stop emitting the codes entirely.
2. **Accept and document.** GRBL reports `error:20` and continues to the next line. Framing already
   proved geometry is correct with those errors present. Two cosmetic complaints per job is not a
   defect worth engineering around — but it must be stated plainly in the README so Ultra owners
   do not think their setup is broken.

## Next

- One live marking run with air **off**, counting `err:20`. If it is still 2, that confirms `M9`
  is the rejected code and settles this completely.
- Fresh `prefs.ini` to record the real stored values for the profile generator.
