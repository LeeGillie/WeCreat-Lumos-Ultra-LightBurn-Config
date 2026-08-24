# Stage 3 — LightBurn connection (no output)

> **No beam.** Connect only. Do not run a job yet.

## My setup

- Profile imported: `WeCreat-Lumos-Ultra-________.lbdev`
- LightBurn version: (2.1.02 or newer strongly recommended — earlier builds desynchronise on
  WeCreat's extra `ok` responses)
- LightBurn licence: ☐ Core ☐ Pro
- MakeIt closed entirely? ☐ yes — *"Port failed to open"* almost always means MakeIt is holding
  the port
- COM port selected:

## Did it connect?

- ☐ Connected and stable
- ☐ Connected then dropped
- ☐ "Port failed to open — already in use?"
- ☐ Stuck at "Waiting for connection…"
- ☐ Shows connected but reports busy / 99 %
- ☐ Other:

## Console output on connect

```
<paste everything, including the banner and any stray ok lines>
```

## Basic interaction

| Action | Result |
|---|---|
| `?` in Console | |
| Move window — jog X+ | |
| Move window — jog Y+ | |
| "Get Position" | |
| Home (if you dare — say if you skipped it) | |

## Device settings that needed changing

The draft profiles are a starting guess. If you had to change something to get a connection,
that is a profile bug and we want it.

| Setting | Draft value | What actually worked |
|---|---|---|
| Baud rate | 1000000 | |
| Workspace W × H | | |
| MirrorX / MirrorY | false / true | |
| CutOrigin | 2 | |
| EnableZ | false | |
| Other | | |

## Notes

<anything else — error dialogs, LightBurn version differences, whether an older/newer LightBurn behaved differently>
