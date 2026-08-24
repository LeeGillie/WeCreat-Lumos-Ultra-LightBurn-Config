# Stage 5 — M-code discovery (differential MakeIt capture)

> **No experimentation on the machine.** You are watching what MakeIt already does, not sending
> anything yourself. This is how the Ultra's M-code table gets written, and it is completely safe.

## Method

Run **the same tiny job twice**, changing **exactly one variable**, and diff the G-code.

Capture by either:

- **Wireshark on the RNDIS interface** — grab the body of `POST /process/upload`
  (filter: `http.request.uri contains "upload"`), or
- **MakeIt's hidden console** — the same one documented for force-OTA (`Ctrl+Shift+P`)

## My setup

- MakeIt version:
- Machine firmware version:
- Sources fitted / lens installed:
- Capture method:

## The variable I changed

☐ UV source → MOPA source **← highest value: isolates the source-select M-code**
☐ MOPA pulse width A → B **← highest value: shows whether pulse width is expressible at all**
☐ MOPA frequency A → B
☐ Focus height A → B
☐ Vector job → raster job
☐ Purple lens → green lens
☐ Plain job → rotary job **← reveals the rotary axis letter**
☐ Plain job → slide job **← reveals the slide axis**
☐ Plain job → conveyor job **← reveals the feed command**
☐ Surface job → K9 internal job
☐ Other: ______

### Job A settings

```
<the exact settings you used>
```

### Job B settings

```
<identical except for the one variable>
```

## The diff

**Post the diff, not the whole file.** Whole files are large and mostly identical.

```diff
<paste the differing lines with a little context>
```

## Full start block

Even if it duplicates other reports, please paste the Ultra's complete start and end block —
this is the thing nobody has:

```
StartGCode:
<paste>

EndGCode:
<paste>
```

## What I think it means

| Code | Params | My reading | Confidence |
|---|---|---|---|
| | | | ☐ confirmed by the diff ☐ inferred ☐ guess |

Please grade honestly. `inferred` is a perfectly good contribution;
[see CONTRIBUTING.md](../../CONTRIBUTING.md). **"I sent it and nothing bad happened" is not
evidence of meaning** and will not be accepted into the dictionary.

## Notes
