# Stage 1 — Serial identity

> **No beam.** Talk to the port directly, before involving LightBurn, so you see the raw truth.
>
> **Send only the read-only probes listed below.** Do not send `M1`, `M6`, `M16`, `M17`, `M18`,
> `M19`, `M57`, `M107`, or any other M-code. WeCreat renumbers them between models and nothing
> is known about the Ultra's set. See [SAFETY.md](../../SAFETY.md).

## My setup

- Sources fitted / lens installed:
- Terminal used (PuTTY / miniterm / screen):
- COM port / device node:

## Baud rate

Which worked? (Lumos uses 1 000 000; Vision family uses 500 000)

- ☐ 1000000  ☐ 921600  ☐ 500000  ☐ 230400  ☐ 115200  ☐ other: ______
- ☐ It's a CDC-ACM gadget and baud appears not to matter

## Connect banner

Power-cycle the machine with the terminal attached and paste **everything**, including stray
`ok` lines. The Lumos produces `[WeCreat Lumos :ver 000207]`.

```
<paste here>
```

- Exact banner string:
- Number of unsolicited `ok` lines around it:

## Read-only probes

| Probe | Reply (paste literally) |
|---|---|
| `?` | |
| `$$` | |
| `$I` | |
| `$#` | |
| `$G` | |
| `M27` | |

### `$$` full dump

**No WeCreat machine's `$$` output has ever been published, for any model.** If yours answers,
this table is a first. If it returns nothing at all, that is equally a finding — say so.

```
<paste the whole table, or write: no response>
```

Of particular interest if present: `$30` (max spindle → confirms `S_Scale`), `$110`/`$111` (max
rates), `$130`/`$131` (max travel → confirms the real field size), `$32` (laser mode).

## `M27` response format

`weburn` parses a reply shaped `M27 X…,Y…,Z…` but nobody has published a real one.

```
<paste literally>
```

## Notes

<anything surprising — timeouts, garbage, resets>
