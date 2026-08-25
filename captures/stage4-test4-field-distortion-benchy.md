# Stage 4, Test 4 — field distortion at 200 mm: none detectable ✅

**Date:** 2026-08-25 · **Machine:** BENCHY / Lumos Ultra · **Lens:** red / MOPA (`F290`, 200 mm field)
**Contributor:** Lee Gillie · **Evidence grade:** CONFIRMED-hardware

**This was the highest-risk open question in the project.** If the firmware's galvo field
correction did not carry through the G-code path, we would have had nowhere to put a correction of
our own — LightBurn gates its lens-correction UI to galvo device classes we are not using. It
carries.

## Method — a software long exposure

Framing is single-pass, so there is no persistent outline to photograph
([why](stage4-mirror-origin-benchy.md)). Instead: **video of the framing run, then a per-pixel
maximum across every frame.** That integrates the travelling dot into a complete traced square —
the same result as a long exposure, without needing a long exposure.

- Source: 1280 × 720, 600 frames, 10 s (a 1:03 framing run, sped up)
- Composite: per-pixel `max()` over all 600 frames
- Trace isolated as `R − max(G,B) > 60` and `R > 90`
- Edge extracted as the per-column centroid of trace pixels
- Straight line fitted, then re-fitted with 2.5σ outlier rejection (741 of 788 points kept)

**Why an oblique camera angle is fine:** perspective projection maps straight lines to straight
lines. The square photographs as a trapezoid, but a *curve* cannot be manufactured by viewing
angle. Bow, if present, would survive.

## Result — top edge, the only one fully in frame

| Measure | pixels | mm |
|---|---|---|
| Edge length (corner to corner) | 779.1 | 200.0 (scale reference) |
| Residual RMS about a straight line | 0.67 | **0.17** |
| Max deviation | 1.67 | **0.43** |
| **Quadratic sagitta (bow at mid-span)** | **0.39** | **0.10** |

Residuals binned across the span, in pixels:

```
x  288- 352   -0.46
x  352- 417   +0.14
x  417- 482   -0.46
x  482- 547   +0.21
x  547- 612   +0.30
x  612- 677   +0.32
x  677- 742   +0.47
x  742- 807   +0.06
x  807- 872   +0.09
x  872- 937   +0.03
x  937-1002   -0.25
x 1002-1067   -0.43
```

Ends slightly negative, middle slightly positive — the *shape* of a barrel bow, but at an
amplitude of 0.4 px against a residual RMS of 0.67 px. **It is at or below the noise floor.**

> ### Conclusion: bow over a 200 mm span is under 0.2 mm, and probably under 0.1 mm.
>
> That is 0.05 % of the span. **The controller's own field correction is applied to G-code motion,
> not only to MakeIt's jobs.** Nothing needs correcting in LightBurn, which is fortunate, because
> nothing could be.

## Honest limits of this measurement

- **Only the top edge is fully in frame.** Left and right edges run out of shot; the bottom edge is
  clipped. Their partial fits gave sagittas of 0.07 mm and 0.42 mm, but their scale factors are
  unreliable because the visible length is not the full 200 mm. Not quoted as results.
- **The camera's own lens distortion is uncorrected** and is plausibly the same order as what we
  are trying to measure. This bounds the result rather than invalidating it — we can say bow is
  *small*, not that it is *zero*.
- **Resolution floor is roughly 0.2 mm.** A defect below that would not show.
- One edge is not four. A full check wants the camera square-on and the whole square in frame.

None of that changes the practical answer: there is no gross distortion, and no distortion large
enough to matter for the marking this configuration is for.

## Bonus finding — all four corners reached

The 200 mm square traced completely, out to a field the lenses are rated for and the machine drives
5 % past. No clipping, no truncation, no alarm.

## Bonus finding — the centre dot is a separate indicator, always on

The open question from [Test 2](stage4-mirror-origin-benchy.md) is settled by counting frames:

| | frames |
|---|---|
| Centre dot **and** moving trace visible together | **455** |
| Centre dot only (between passes) | 145 |
| Trace but no centre dot | **0** |
| Centre dot present | **600 / 600 — 100 %** |

It never goes out, and it is lit in 455 frames while the galvo is demonstrably pointing somewhere
else. **It is a separate, always-on fixed focus indicator, not the galvo parked at field centre.**

Practical consequence: do not use the centre dot to judge position or origin. It is a focus aid.

## Status

**Test 4 passed. Stage 4 is complete.** Origin, mirroring and field geometry are all resolved, and
the distortion risk that could have capped what v1.0 promises is retired.

---

## Caveat on the always-on claim — raised by the operator

**The video was sped up ~6× before analysis.** If the editor produced that by *blending* adjacent
frames rather than *dropping* them, a dot that was only intermittently lit could smear across
frames and read as continuous. The frame counts above are taken from individual frames of the
sped-up file, not from the composite, but they inherit that assumption.

How much does it weaken the conclusion? Less than it first appears, for one reason:

> **`trace but no centre dot` = 0 frames.**

If the centre dot were the galvo parked at field centre, then during a framing pass — when the
galvo is demonstrably somewhere else — there should be many frames showing the trace and no centre
dot. There are none, across 455 frames where both appear. Blending could fabricate a handful of
such coincidences at pass boundaries. It cannot fabricate 455 of 600 while producing zero
counter-examples.

**Still worth one second of direct confirmation.** Look at the bed during a framing pass and check
whether the centre dot is lit at the same time as the travelling dot. Eyes beat inference here, and
it costs nothing.

**Current grade: INFERRED-strong, pending that look.** Downgraded from the CONFIRMED implied above.
