# The control-mode latch — CONFIRMED

**Date:** 2026-08-24 · **Machine:** BENCHY / Lumos Ultra · **Contributor:** Lee Gillie

> **Operationally the most important thing found so far.** It is not documented by WeCreat, it is
> not mentioned in any community guide, and it changes how anyone must work with this machine.

## What happened

After [Stage 1](stage1-serial-benchy.md) opened `COM7` and sent read-only GRBL queries
(`?`, `$$`, `$I`, `$#`, `$G`), MakeIt displayed:

> **Warning**
>
> Machine is now connected to LightBurn. To restore Make It control, the following actions need
> to be taken:
>
> 1. Please close the LightBurn software
> 2. After restarting the device, reconnect Make It

**LightBurn was never involved.** The client was a PowerShell script issuing five GRBL query
commands. The controller cannot distinguish one serial client from another — it only knows that
**the USB serial port was opened and spoken to**.

## The finding

**Opening the Ultra's serial port latches the controller out of MakeIt control, and recovery
requires a power cycle of the machine.** Closing the serial client is not sufficient.

| | |
|---|---|
| **Trigger** | Any client opening the CH340 serial port and sending commands. LightBurn, a terminal, or a script — the controller treats them identically |
| **Effect** | The SBC/MakeIt control path is handed over to the serial stream. MakeIt loses control |
| **Recovery** | Close the serial client **and power-cycle the machine.** Restarting MakeIt alone will not do it |
| **Reversible?** | Yes, completely. Nothing is damaged or persistently changed |
| **Grade** | **CONFIRMED-hardware** — observed directly, with a vendor dialog stating the recovery procedure |

## Why this matters

1. **You cannot freely alternate between MakeIt and LightBurn.** Every switch back to MakeIt
   costs a power cycle. Plan work in blocks by software, not task by task.
2. **It affects our own Stage 5 method.** "Run a job in MakeIt, then grab the G-code" requires
   MakeIt to *have* control — so the machine must be power-cycled after any serial probe before
   MakeIt will drive it again.
3. **It explains the community's most common WeCreat complaint.** The recurring "Port failed to
   open — already in use?" and "laser busy" reports are the same mechanism seen from the other
   direction: the two control paths are mutually exclusive, and the machine latches.
4. **It is a real usability trap.** Someone mid-project in MakeIt who opens LightBurn to check
   something loses machine control until they power-cycle — with no warning beforehand.

## This is very likely what `M16` / `M17` do

Every WeCreat `.lbdev` start block contains `M16`, labelled by WeCreat as **"Enable Umode"**, with
`M17` as **"DisEnable Umode"**. Nobody has known what "U mode" means — see
[04-mcode-dictionary.md](../docs/04-mcode-dictionary.md#what-is-u-mode), where the leading
hypothesis was **"USB mode" — handing MCU control from the SBC front-end to the USB serial
stream**.

This latch is exactly that behaviour, observed from the outside. The evidence now:

- It is in the unconditional start block of **every** WeCreat machine profile, which fits a
  fundamental control-path switch and fits nothing else proposed.
- An explicit inverse (`M17`) exists, which a mode handover needs and a rotary/air-assist toggle
  would not.
- The architecture requires such a switch: the SBC normally owns the MCU via `/test/cmd/mcu`,
  so something must arbitrate when a serial client wants it instead.
- The observed effect — serial client takes control, MakeIt loses it — is precisely a U/USB-mode
  enable.

**Upgraded from UNKNOWN to INFERRED (strong).** Still not `CONFIRMED`: we have not seen `M17`
restore MakeIt control, and we did not send `M16` — the latch happened on port open alone, which
may mean the firmware asserts it implicitly rather than waiting for the command.

**A clean test exists that sends nothing:** power-cycle, connect MakeIt, confirm control, then
grab the job G-code (Stage 5) and look at whether `M16` appears in MakeIt's own output. If MakeIt
emits `M16`/`M17` around its jobs, the meaning is settled from the vendor's own G-code.

## Practical procedure

```
Working in MakeIt      ->  power-cycle the machine first if anything has touched COM7
Working in LightBurn   ->  close MakeIt first (it holds the port)
Switching back         ->  close the LightBurn-side client, power-cycle, reconnect MakeIt
```

Recorded in [SAFETY.md](../SAFETY.md) and in the
[bring-up plan](../docs/03-bringup-plan.md), since every future contributor will hit this.
