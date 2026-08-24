# captures/

Where hardware findings live. This is the part of the repository that turns inference into fact.

## How to contribute a capture

1. Copy the matching template from [`templates/`](templates/).
2. Fill it in. Blanks are fine — write "not tested" rather than guessing.
3. Save it here as `<stage>-<yourhandle>.md`, e.g. `stage0-usb-leeg.md`.
4. Open a PR, or paste it into an issue and someone will file it.

## Templates

| Template | Stage | Needs a beam? |
|---|---|---|
| `usb-enumeration.md` | 0 | **No** |
| `serial-banner.md` | 1 | **No** |
| `rest-probe.md` | 2 | **No** |
| `lightburn-connect.md` | 3 | **No** |
| `field-calibration.md` | 4 | Red dot only |
| `mcode-discovery.md` | 5 | **No** — you are watching MakeIt, not experimenting |

Four of the six need no beam at all, and they carry most of the project's unanswered questions.

## Rules

- **Raw is better than tidy.** Paste the literal console output. Do not retype it.
- **Say what you did NOT test.** A capture that quietly omits a step reads as a negative result.
- Include your machine configuration every time — source, lens, accessories fitted, MakeIt
  version, LightBurn version, firmware banner. Almost every open question here has turned out to
  be model- or firmware-specific.
- **Near misses are welcome.** If something moved or fired unexpectedly, that belongs here more
  than any successful test does.

## What is gitignored

`.pcap`, `.pcapng`, and image files are ignored — they are large and often contain more than you
intend. Extract the relevant bytes into the markdown instead. If a full capture genuinely
matters, link it rather than committing it.
