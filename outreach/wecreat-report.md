# Draft — report to WeCreat support

**Why bother.** Only WeCreat can fix this. The status report is firmware, on their side of the MCU
boundary, and no LightBurn configuration reaches it. They are also the only ones who can answer
whether an official Ultra config is coming.

**Tone matters more here than in the other two.** They advertise LightBurn support on the Ultra
product page and have not shipped a config for it. That is worth being generous about rather than
scoring points on — a support agent who feels attacked forwards nothing, and this needs to reach an
engineer.

**Ask for one specific thing.** Vague reports die in tier one.

---

**Subject: Lumos Ultra — GRBL status report returns `Idle` during job execution (LightBurn
streaming)**

Hello,

I own a Lumos Ultra (100 W MOPA) and I've been setting it up with LightBurn, which the Ultra product
page lists as supported software. I've found what I believe is a firmware issue and I wanted to
report it properly rather than just complain in a forum.

I'd be glad to be told I've got this wrong.

**The observation**

Over the USB serial connection, the controller's GRBL status report appears to return a fixed state.
Every `?` query answers:

```
<Idle|MPos:2.748,18.237,0.000|FS:0,0|Pn:Z|WCO:0.000,0.000,0.000>
```

- `MPos` is **correct and live** — real position, updating during motion
- the **state field is always `Idle`**, including while a job is actively running
- **`FS` is always `0,0`** rather than reporting actual feed and speed

The clearest case: if I send `!` (feed hold) in the middle of a job, the controller still answers
`Idle`. A machine that has just been commanded to hold reports itself as idle.

**Why it matters**

LightBurn uses that state to pace how fast it sends commands. Because the machine always reports
itself idle and never busy, long jobs stall part-way through — no alarm, no disconnection, fan still
running, engraving simply stops. Pressing Pause and then Resume restarts it.

MakeIt is unaffected, and I think I understand why: MakeIt uploads the job to the machine's SD card
over the USB network interface and lets the controller run it locally. It never streams over the
serial port, so it never depends on this. That's a perfectly reasonable design — it just means the
serial acknowledgement path may not have had the same exercise.

**What I've ruled out**

Cable and port (direct connection, several ports), LightBurn transfer modes, DTR, position-query
polling, laser-fire button, and the Z-axis settings that fix the "Busy after framing" problem on
other WeCreat machines. None changed the behaviour. MakeIt runs flawlessly on the same cable, which
is what pointed me at the streaming path rather than the hardware.

**My question**

Is the GRBL status report on Lumos-family firmware intended to report `Run` and `Hold` states, and
if so, is this a known issue on the Ultra? I'd also be grateful to know whether an official
LightBurn configuration for the Lumos Ultra is planned — I've built an unofficial one and would much
rather point people at yours.

One smaller thing that may be useful: the Ultra identifies itself over serial as
`[WeCreat Lumos :ver 000240]`, with nothing distinguishing it from a Lumos. That means your official
Lumos LightBurn profile connects to an Ultra without any warning and applies a 116 × 116 mm
workspace instead of 210 × 210 mm. Owners could easily ruin work without understanding why. A
version or model string that differed would prevent that entirely.

I've documented everything publicly, with the raw captures, in case it's useful to your engineers:

https://github.com/LeeGillie/WeCreat-Lumos-Ultra-LightBurn-Config

Thank you — it's a genuinely impressive machine and I'd like to get more out of it.

Lee Gillie
