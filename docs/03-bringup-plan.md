# 03 — Staged Bring-Up Plan

Ordered so that the cheapest, safest tests come first and the highest-risk ones come last. Each
stage names what you do, what result means what, and where to file it.

**Read [SAFETY.md](../SAFETY.md) first.** Stages 0–2 involve no beam at all, and answer most of
the project's open questions.

Every stage has a capture template in [`captures/templates/`](../captures/templates/). File
results as an issue or a PR adding a file under `captures/`.

---

## Stage 0 — USB enumeration *(no beam, no software, 2 minutes)*

**This is the single most valuable test in the project.** It settles the architecture question.

```powershell
# with the Ultra powered on and connected by USB:
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1 > .\captures\ultra-usb-<yourname>.txt
```

On Linux: `lsusb`, `lsusb -v -d <vid:pid>`, `dmesg | tail -60`, `ls -l /dev/serial/by-id/`, `ip -br a`.

**Interpretation**

| What you see | What it means |
|---|---|
| `VID_0525&PID_A4A2` or `VID_1D6B&PID_0104` under Network adapters | Linux USB gadget — same architecture as the Lumos/Vision. **Expected.** |
| A COM port alongside it (`VID_1A86` CH340, or a CDC-ACM gadget) | The serial path exists. Proceed to Stage 1 |
| A COM port but **no** RNDIS | Simpler than expected; the REST path may be gone |
| `VID_9588` (BJJCZ/JCZ) or a WinUSB device with no COM port | **The Ultra is a real galvo controller and this project's architecture is wrong.** Stop and open an issue immediately — that is a very good outcome, it means LightBurn's galvo features are available |
| Two COM ports | Known WeCreat quirk — only one is functional |

→ File as issue type **Feature status report**, question #1.

## Stage 1 — Serial identity *(no beam)*

Talk to the port directly, *before* involving LightBurn, so you see the raw truth.

```
# Windows: PuTTY → Serial, or
python -m serial.tools.miniterm COM<n> 1000000
# try also 921600, 500000, 230400, 115200
```

Power-cycle the machine while connected and capture the banner.

**Expect** something shaped like `[WeCreat Lumos Ultra :ver ######]` — the Lumos produces
`[WeCreat Lumos :ver 000207]`, plus **extra unsolicited `ok` lines**. Record the exact string;
LightBurn's device detection depends on it.

Then, one at a time, send these **read-only** probes:

| Probe | Looking for |
|---|---|
| `?` | A real GRBL status frame `<Idle\|MPos:0.000,0.000,0.000\|…>` |
| `$$` | The settings table. **No WeCreat `$$` output has ever been published, for any model.** If it returns nothing, that is itself the finding |
| `$I` | Build info |
| `$#` | Work coordinate offsets |
| `$G` | Parser state |

**Do not send anything else.** Not `M1`, `M6`, `M16`, `M17`, `M18`, `M19`, `M57`, `M107`.

> **A note on `M27`.** Earlier drafts of this document listed `M27` among the safe probes, on the
> grounds that `weburn` parses a reply shaped `M27 X…,Y…,Z…` from the Vision. That was
> inconsistent with our own rule in [SAFETY.md](../SAFETY.md) — *no blind M-codes* — because
> WeCreat renumbers M-codes between models and `M27` is unverified on the Ultra. It is now
> **opt-in only**: `tools/stage1-serial-probe.ps1 -IncludeM27`, which warns and pauses first.
> The `$`-commands above are GRBL queries, not WeCreat M-codes, and carry no such risk.

### The scripted way

`tools/stage1-serial-probe.ps1` does all of the above with nothing but Windows PowerShell — no
Python, no PuTTY. It auto-detects the CH340 port, leaves DTR and RTS alone so the controller is
not reset, sends only the `$` queries and `?`, and writes the transcript into `captures/`.

```powershell
.\tools\stage1-serial-probe.ps1                 # auto-detect, 1000000 baud
.\tools\stage1-serial-probe.ps1 -AllBauds       # try each known baud in turn
```

→ Template: `captures/templates/serial-banner.md`

## Stage 2 — Network side *(no beam, but see the interlock warning)*

**Confirmed on a real Ultra:** the RNDIS adapter comes up at **192.168.42.100/24**, which puts
the controller on `192.168.42.0/24` — almost certainly **`192.168.42.1`**. Note this is a
*private USB-only* subnet; it is not reachable from anywhere else on your LAN.

`tools/stage2-rest-probe.ps1` auto-detects that subnet, scans ports 22/80/8080/8082, and calls
only the read-only endpoints. It never calls `/test/cmd/mcu`, and it skips the head-moving
autofocus probe unless you pass `-AllowAutofocus`.

```powershell
.\tools\stage2-rest-probe.ps1
.\tools\stage2-rest-probe.ps1 -Target 192.168.42.1
```

By hand, if you prefer:

```bash
curl -X POST "http://<ip>:8080/process/status"
curl "http://<ip>:8080/camera/take_photo" -o test.jpg
curl "http://<ip>:8080/device/camera/download"
curl "http://<ip>:8080/device/camera/measure_distance?x=105&y=105"
# and check what else is listening
nc -vz <ip> 22 ; nc -vz <ip> 8082
```

**⚠️ Do not use `POST /test/cmd/mcu`.** That endpoint fires the laser regardless of lid position.

**Interpretation:** if these answer, the `weburn` endpoint map survives into the Ultra and a
bridge is viable — which is the only route to camera and autofocus features the serial path
cannot reach. If 8080 is gone or changed, the real API can be captured with Wireshark on the
RNDIS interface while MakeIt runs a job (Stage 5).

→ Template: `captures/templates/rest-probe.md`

## Stage 3 — LightBurn connection, no output *(no beam)*

Import `profiles/draft/WeCreat-Lumos-Ultra-UV-Purple-210.lbdev` (Laser window → Devices →
Import). It ships with empty start/end G-code deliberately.

Connect. Watch the Console.

- Does LightBurn report the machine as connected?
- Does the banner appear?
- Does `?` produce sane position?
- Does the Console show "Starting stream" on a job?

**Do not run a job yet.** If the connection is unstable, note your LightBurn version — 2.1.00
added "Allow for extra ok's from WeCreat firmware" and 2.1.02 reverted the GRBL protocol to
"GRBL-ish" specifically for machines like this. Older versions desynchronise and produce the
perennial "laser busy" / stuck-at-99 % symptom.

→ Template: `captures/templates/lightburn-connect.md`

## Stage 4 — Motion and framing *(red dot only, no laser)*

With the **purple UV lens installed** and confirmed, and the bed empty:

1. Frame a 10 mm square. Then 50 mm. Then 100 mm. Then 200 mm.
2. Measure the framed rectangle with calipers or a steel rule.
3. Check orientation: does the framed shape match what's on screen, or is it mirrored/rotated?

**What you are calibrating:** `Width`/`Height`, `MirrorX`/`MirrorY`, `CutOrigin`, and
`ProcessOffsetX`/`Y` in the profile. The vendor Lumos profile uses `MirrorY: true` and
`CutOrigin: 2`; whether the Ultra matches is unknown.

If the red dot does not come on, try `M21S1` — that code is well attested on the Vision family,
though not on the Ultra.

→ Template: `captures/templates/field-calibration.md`

## Stage 5 — Differential MakeIt capture *(the M-code goldmine)*

This is how the Ultra's M-code table gets written, and it needs no risky experimentation at all —
you simply watch what MakeIt already does.

Method: run **the same tiny job twice**, changing **exactly one variable**, and diff the G-code.
Capture either with Wireshark on the RNDIS interface (grab the body of `POST /process/upload`)
or through MakeIt's hidden console.

| Change exactly this | Isolates |
|---|---|
| UV source → MOPA source | **The source-select M-code** (the Ultra's analogue of the Lumos `M18`) |
| MOPA pulse width A → B | **Whether pulse width is expressible in G-code at all** |
| MOPA frequency A → B | Frequency control |
| Focus height A → B | Whether focus is a plain `G0 Z…` |
| Vector job → raster job | Whether `M1S1`/`M1S0` mode switching survives |
| Purple lens → green lens | Whether the lens is announced to the controller |
| Plain job → rotary job | **The rotary axis letter: `A`, `U`, or remapped `Y`** |
| Plain job → slide job | The slide axis |
| Plain job → conveyor job | The conveyor feed command |
| Surface job → K9 internal job | Whether depth layers are Z moves or something else |

Post the **diff**, not the whole file, plus the two job settings. → Template:
`captures/templates/mcode-discovery.md`

## Stage 6 — First UV marks *(beam, lowest power)*

Purple lens. Scrap material. UV goggles (190–550 nm). Lowest power / highest speed that marks.

1. A 10 mm square outline.
2. A speed/power grid — LightBurn's Material Test generator.
3. Measure the square. Adjust `Width`/`Height` scaling and re-measure.

→ File the resulting numbers as a **calibration data** issue.

## Stage 7 — MOPA *(beam, highest risk)*

Red lens. MOPA goggles (800–1100 nm). Metal scrap, never anything reflective and unsecured.

Start absurdly low. Confirm the source actually switched before assuming the settings apply —
if UV is still active and you have dialled in MOPA numbers, you will get a surprise.

Establish: does power scale sensibly? Does speed? What are the practical fill rates over the
serial link versus MakeIt (Stage 10)?

## Stage 8 — Rotary

Precedent from the Vision passthrough conveyor: LightBurn's ordinary **rotary setup on the A
axis**. WeCreat's own tumbler guide says "Set Axis to A". The vendor Lumos profile carries
`rotaryAxis: 3`, `rotarySteps: 360`, `rotaryIsChuck: true` — rotary settings live **inside the
device profile** for GRBL devices, which is convenient for us.

Determine: steps per rotation, direction, whether `M16`/`M17` are involved.

## Stage 9 — Slide extension

LightBurn's Split Marking is galvo-only, so automatic slide-driven tiling is not available.
What may be possible: driving the slide as a second axis manually, or tiling by hand.

First find out how MakeIt addresses the slide motor (Stage 5).

## Stage 10 — Conveyor, and throughput benchmark

Conveyor: feed increment, whether it is bidirectional, and the feed command.

Benchmark: run the same fill in MakeIt and in LightBurn and time both. If LightBurn's serial fill
is dramatically slower, the project's centre of gravity should shift toward a bulk-upload bridge
rather than live streaming.

## Stage 11 — K9 internal engraving

Expected outcome: **not reachable from LightBurn.** LightBurn's depth-map and 3D-slice modes are
galvo-class features and are confirmed non-functional on the Lumos even with LightBurn Pro.
Internal engraving additionally needs a coordinated focal-depth sweep, not a surface Z.

Worth testing anyway: does ordinary 2D surface marking work through the green lens, at 70 × 70 mm?
That would at least make the green lens useful for something in LightBurn.

---

## What to do if you can only do one thing

Stage 0. Two minutes, no beam, and it answers the question everything else depends on.
