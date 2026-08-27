# MakeIt stages its G-code on the PC — and every move in it is absolute

**Date:** 2026-08-27 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie
**Evidence grade:** CONFIRMED-hardware — read directly from WeCreat's own staged job file
**Tools:** [`tools/find-makeit-cache.ps1`](../tools/find-makeit-cache.ps1),
[`tools/analyze-gcode.ps1`](../tools/analyze-gcode.ps1)

## Where MakeIt keeps the job

```
%APPDATA%\Wecreat MakeIt!\gcode\gcode.gc       232,835,780 bytes
%APPDATA%\Wecreat MakeIt!\gcode\framing.gc           2,720 bytes
%APPDATA%\Wecreat MakeIt!\logs\main.log         ~19 MB, live
%APPDATA%\Wecreat MakeIt!\logs\succeedImg\      emboss001..255.jpg, ~258 KB each
```

MakeIt is an Electron application and writes the complete generated toolpath to disk before
uploading it. **No packet capture is needed to see what WeCreat's own software produces**, and
no commands need to be sent to the machine.

The `succeedImg` folder holds one preview JPEG per layer, numbered to **255** — this capture is a
deep emboss job, which is the practical face of the "256 layers" question
([docs/09](../docs/09-k9-and-mopa-limits.md)).

## The file, measured

| | |
|---|---|
| Size | **232,835,780 bytes** (222 MB) |
| Lines | **11,276,586** |
| Motion commands | **11,275,714** (`G1` 10,968,120 + `G0` 307,594) |
| Average line | 20.6 bytes |
| Extents | X 80.860 – 122.901 · Y 81.889 – 124.292 (≈ 42 × 42 mm) |
| Header | `;wecreat 3.0.6` · `;canvas border: 0 0 210 210` |

It is a **single job**, not an accumulating log: one header, one `M6` terminator, and exactly two
`G90` statements — one at the start and one in the shutdown block.

`;canvas border: 0 0 210 210` and `M107X-105Y-105` independently corroborate the field size and
origin offset established in [Stage 4](stage4-mirror-origin-benchy.md).

## 🎯 Finding 1 — MakeIt never uses relative mode

```
G90 (absolute) switches : 2
G91 (relative) switches : 0
moves in ABSOLUTE mode  : 11,275,714   (100.00 %)
moves in RELATIVE mode  :          0   (  0.00 %)
```

**Zero `G91` in 11.3 million motion commands.** WeCreat's own toolpath generator does not use
relative mode on this controller at all.

Compare LightBurn's fill output on the same machine
([evidence](stage5-G91-relative-mode-CONFIRMED.md)):

| | MakeIt (this file) | LightBurn `Plain Fill` |
|---|---|---|
| Motion commands | 11,275,714 | 9,637 |
| In relative mode | **0 (0.00 %)** | 9,634 (99.97 %) |
| Absolute re-anchors | every move | 2 |

### What this does and does not prove

**It does not prove WeCreat chose absolute for safety.** MakeIt uploads the file and the controller
reads it locally, so it has no bandwidth pressure to compress against. `G91` is a streaming
optimisation, and MakeIt does not stream. The choice is likely incidental.

**What it does establish** is that the controller's absolute path is exercised at enormous scale on
every MakeIt job — 11 million absolute moves in this one file. There is no case that `G90` is a
rarely-trodden or slow path on this hardware.

## 🎯 Finding 2 — the transfer arithmetic rules streaming out

At 1,000,000 baud, 8N1, ten bits carry one byte, giving a theoretical ceiling of 100,000 bytes/s.

```
232,835,780 bytes ÷ 100,000 B/s ≈ 2,328 s ≈ 39 minutes
```

That is **pure payload at perfect line utilisation**, before a single acknowledgement round trip,
and before the protocol stalls that are the subject of this investigation. With a ~128-byte window
and 20.6-byte lines, roughly six lines are in flight at a time across 11.3 million of them.

**Streaming a job of this size is not slow. It is not possible.** This is the clearest available
statement of why upload-to-device is the correct architecture for this machine, and it is measured
rather than argued.

It also reframes Jon C's remark that *"with 127 bytes of buffer, for a galvo machine we're going to
be running dry very quickly"* — the buffer fix helps, but no buffer size makes a 222 MB job
streamable.

## 🎯 Finding 3 — frequency and pulse width change 282 times mid-job

```
M38  (frequency)    282
M39  (pulse width)  282
```

Against **one** of each in the small single-layer job captured on 2026-08-24
([stage5](stage5-jobgcode-mf-151-benchy-20260824-103612.txt)).

**The controller accepts MOPA frequency and pulse-width changes mid-job**, and MakeIt uses that
capability heavily — 282 parameter changes within one file. Opening values here are `M38F60` and
`M39P250`, against `M38F151` / `M39P200` in the earlier job.

This is directly relevant to LightBurn's **Enable Q-Pulse Options** toggle: per-layer pulse control
is not merely permitted by this firmware, it is what the vendor's own software does routinely.
[docs/09](../docs/09-k9-and-mopa-limits.md) should be revised accordingly.

## Other observations

- **`G0Z48.77`** appears at the start and again in the shutdown block. MakeIt sets Z once per job.
  Compare `/mnt/SDCARD/config/heightZ.txt` = `43.35` and `greenZ.txt` = `8.03` — 48.77 matches
  neither, so the relationship between the stored Z constants and the commanded Z is **UNKNOWN**.
- **`M46A0.9764B20`** here, against `M46A1B0` in the earlier job. `A1B0` is an identity pair, which
  reads as a scale-and-offset. **INFERRED — do not send.**
- **`S` values are continuously modulated** — `S0`, `S59`, `S122`, `S514`, `S345`, `S67`, `S20` —
  greyscale power per segment, consistent with a depth map.
- `G1` outnumbers `G0` by 36:1, as expected for a dense raster.

## Caveats

- This file is dated **10:16**, while the run observed at ~12:40 did not update it. Whether the
  cache is written for every job type, or only for some, is **not yet established**. Re-check after
  a known job of each kind.
- The 39-minute figure is an upper-bound-friendly estimate: it assumes perfect utilisation and no
  protocol overhead, so real streaming would be worse, not better.

## Next

1. Run `analyze-gcode.ps1` on `captures/Plain Fill.gc` and publish the two censuses side by side.
2. Grep `logs\main.log` for the upload endpoint and method — the one part of the bridge that the
   read-only probes could not reach.
3. Revisit [docs/09](../docs/09-k9-and-mopa-limits.md) with Finding 3.
