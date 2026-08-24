# Stage 4 — Field calibration (red dot / framing)

> **Red dot only — no laser output.** Bed empty. Correct lens confirmed installed.

## My setup

- Profile: `WeCreat-Lumos-Ultra-________.lbdev`
- **Lens physically installed:** ☐ Purple ☐ Green ☐ Red
- Source selected:
- Did the red dot come on at all? ☐ yes ☐ no ☐ only after sending `M21S1`

## Framing measurements

Draw a square, frame it, measure the framed rectangle with calipers or a steel rule.

| Nominal | Measured X | Measured Y | Notes |
|---|---|---|---|
| 10 mm | | | |
| 50 mm | | | |
| 100 mm | | | |
| 200 mm | | | (skip if using the 70 mm green lens) |

Scale error: X = ______ %   Y = ______ %

## Orientation

- Does the framed shape match what's on screen? ☐ yes ☐ mirrored in X ☐ mirrored in Y ☐ rotated 90° ☐ rotated 180°
- Which `MirrorX` / `MirrorY` combination fixed it:
- Which `CutOrigin` value put the origin where you expected:

## Field extent

- Where is (0,0) physically? (front-left / rear-left / centre / …)
- Can you frame the full nominal field, or does it stop short?
- Actual usable field measured corner to corner: ______ × ______ mm
- Required `ProcessOffsetX` / `ProcessOffsetY` to centre the field:

## Green lens specifically

- Does the 70 × 70 mm field frame correctly?
- Any evidence the controller knows which lens is fitted (different behaviour without changing the profile)?

## Resulting profile values

Paste the values that actually worked, so they can go into `tools/profile-spec.json`:

```
Width               =
Height              =
MirrorX             =
MirrorY             =
CutOrigin           =
ProcessOffsetX      =
ProcessOffsetY      =
EnableProcessOffset =
```

## Notes
