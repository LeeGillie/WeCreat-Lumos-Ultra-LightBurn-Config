# 13 — Setting Up a Test Machine

How to prepare the PC that has a Lumos Ultra physically attached, so it can run the
[bring-up stages](03-bringup-plan.md) and file results back into the repository.

The authoring machine and the test machine are usually different boxes — the laser tends to live
in a workshop or basement, not next to your development workstation. This document assumes that
split. If they are the same machine, skip to [step 3](#3-check-readiness).

**Read [SAFETY.md](../SAFETY.md) before the machine is powered on with a lens installed.**

---

## 1. What the test machine needs

| Requirement | Why | Required? |
|---|---|---|
| Windows 10/11 | The tooling is PowerShell | yes (the scripts are Windows-first; ports welcome) |
| **git** | To clone the repo and commit captures | **yes** |
| **LightBurn 2.1.02 or newer** | 2.1.00 added *"Allow for extra ok's from WeCreat firmware"*; 2.1.02 added a WeCreat device-detection fix and reverted the GRBL protocol to "GRBL-ish". Older builds desynchronise and produce the stuck-at-99 % / "laser busy" symptom | for Stage 3 onward |
| WeCreat MakeIt | Supplies the RNDIS USB driver, and is the reference implementation for Stage 5 captures | strongly recommended |
| Node.js | Only for `asar-tool.js` / `scan-strings.js` (MakeIt inspection) | optional |
| Python + pyserial | Only if you prefer `miniterm` for the Stage 1 serial probe. PuTTY works too | optional |
| Wireshark | Stage 5 differential capture on the RNDIS interface | optional, but it is the route to the M-code table |

Nothing in Stages 0–2 needs LightBurn at all.

## 2. Get the repository onto the test machine

Pick whichever is least friction for you. All three end in the same place.

### Route A — git bundle (no network account needed)

A git bundle is the whole repository, history included, in one file. Works over a shared folder,
RDP clipboard, or a USB stick.

On the authoring machine:

```powershell
cd "<repo>"
git bundle create lumos-ultra-lightburn.bundle --all
git bundle verify lumos-ultra-lightburn.bundle
```

Copy that file across, then on the test machine:

```powershell
cd D:\DevHome                      # or wherever you want it
git clone lumos-ultra-lightburn.bundle "WeCreat Lumos Ultra Lightburn Config"
cd "WeCreat Lumos Ultra Lightburn Config"
git log --oneline                  # confirm the history arrived
```

To send later work back, bundle in the other direction:

```powershell
git bundle create results.bundle --all
# copy back, then on the authoring machine:
git pull <path-to>\results.bundle main
```

### Route B — a private GitHub repo as the transport

Cleaner once you are iterating, because results flow both ways without copying files. A private
repo is **not published** — you can flip it to public later and the history comes with it.

```powershell
# authoring machine
gh repo create wecreat-lumos-ultra-lightburn --private --source=. --remote=origin --push

# test machine
gh auth login          # once
gh repo clone <you>/wecreat-lumos-ultra-lightburn
```

Then the normal loop: test machine commits captures and pushes, authoring machine pulls.

### Route C — plain file copy

If the test machine has no git, copy the working folder across and install git later. You lose
history until then, so prefer A or B if you can.

## 3. Check readiness

With the **Ultra powered on and connected by USB**, and **MakeIt fully closed** (it holds the
serial port):

```powershell
cd "WeCreat Lumos Ultra Lightburn Config"
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1
```

This is read-only. It touches no hardware and fires nothing. It reports installed software,
serial ports, RNDIS gadgets, every USB VID/PID, network adapters, LightBurn version, and whether
`git` / `node` / `python` / `gh` are present — then prints a readiness summary.

**Section 10 is the one to read.** If it says *"No laser detected"*, work through:

- Is the machine powered on, not just plugged in?
- Is MakeIt closed? Check Task Manager for a stray `WeCreat MakeIt!` process.
- Is the RNDIS driver installed? It ships inside MakeIt at
  `…\WeCreat\makeit-builder\resource\driver\win\rndis\` — run `usb-driver-installer-x64.exe`.
- Try a different USB cable and a directly-attached port rather than a hub.

## 4. Run Stage 0 and save the result

This is the single most valuable test in the project — it settles whether the Ultra is a GRBL
serial device or a real galvo controller.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1 `
  > .\captures\stage0-usb-<yourname>.txt
```

Then fill in `captures/templates/usb-enumeration.md`, save it alongside, and commit:

```powershell
git add captures/
git commit -m "Stage 0: USB enumeration on <machine>"
```

What the result means is tabulated in
[03-bringup-plan.md § Stage 0](03-bringup-plan.md#stage-0--usb-enumeration-no-beam-no-software-2-minutes).
The short version: Linux-gadget IDs plus a COM port confirms the current architecture; a BJJCZ/JCZ
ID means the Ultra is a real galvo controller and much more of LightBurn becomes available.

## 5. Then Stage 1

Serial identity — still no beam. Talk to the port directly before involving LightBurn, so you see
the raw truth rather than LightBurn's interpretation of it. Template:
`captures/templates/serial-banner.md`.

Only read-only probes (`?`, `$$`, `$I`, `$#`, `$G`, `M27`). **No M-codes.** WeCreat renumbers them
between models and nothing is known about the Ultra's set.

## 6. Housekeeping on a test machine

- **Close MakeIt before every LightBurn session.** Most "cannot connect" reports trace to this.
- Keep the repository out of `C:\Program Files` and out of OneDrive-synced folders — both cause
  permission and locking surprises with git.
- If the test machine is headless or awkward to sit at, note that everything through Stage 2 is
  scripted and produces a text file you can collect later.
- Do not commit `.pcap` files or photographs; extract the relevant bytes into markdown instead.
  See [`captures/README.md`](../captures/README.md).
