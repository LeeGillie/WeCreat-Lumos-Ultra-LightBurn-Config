# 10 — The `.lbdev` File Format

Two corrections to widely repeated assumptions, up front:

1. **`.lbdev` is JSON, not XML.** There is no root element.
2. **LightBurn 2.x no longer *exports* `.lbdev`.** The Devices window exports a `.lbzip` User
   Bundle. `.lbdev` remains **import-only** — which is exactly why vendors still ship it.

## Structure

A `.lbdev` is a UTF-8 JSON object, pretty-printed with 4-space indent, whose only top-level key
is `DeviceList` — an **array**, so one file can carry several profiles. LightBurn's import dialog
confirms this: *"Select a `.lbzip`, `.lbdev`, or `.lbvendor` file containing one or more device
profiles."*

```json
{
    "DeviceList": [
        {
            "Checklist": "",
            "DefaultCutList": [ ... ],
            "DefaultToolCutList": [],
            "DisplayName": "WeCreat Lumos Ultra - UV Purple 210",
            "GUID": "AbCdEfGhIj",
            "Name": "GRBL",
            "Type": "Serial",
            "Width": 210,
            "Height": 210,
            "MirrorX": false,
            "MirrorY": true,
            "ProcessOffsetX": 0,
            "ProcessOffsetY": 0,
            "EnableProcessOffset": false,
            "HomeOnStartup": false,
            "LastCamera": "",
            "Settings": { ... }
        }
    ]
}
```

### Top-level keys that matter

| Key | Meaning |
|---|---|
| `Name` | **The LightBurn driver type.** `"GRBL"` for every WeCreat machine. Galvo devices would say `"JCZFiber"`, `"BSLFiber"` or `"EZCad3"` |
| `Type` | **The connection type.** `"Serial"`, `"TCP"` |
| `DisplayName` | What the user sees in the Laser window |
| `GUID` | A short identifier string (10 chars in observed files). Must be unique per profile |
| `Width` / `Height` | Workspace in mm. On a GRBL device this *is* the field size |
| `MirrorX` / `MirrorY` | Output mirroring. All WeCreat profiles use `MirrorY: true` |
| `ProcessOffsetX` / `Y` + `EnableProcessOffset` | Rigid offset of the job within the field |
| `Checklist` | **Free text shown before every job.** Our lens/goggle safeguard |
| `LastCamera` | e.g. `"LBHTTP: WeCreat Vision"` |
| `DefaultCutList` | Preloaded layer settings. May be an empty array |
| `Settings` | Flat sub-object, ~90 driver-dependent keys |

### `Settings` keys observed in WeCreat profiles

| Key | Lumos value | Note |
|---|---|---|
| `BaudRate` | `1000000` | Vision family uses `500000` |
| `CommPort` | `"COM3"` | **Vendor leftovers** — should be `"(Choose)"` in a clean profile |
| `S_Scale` | `1000` | Max S value |
| `CutOrigin` | `2` | Job origin corner |
| `EnableZ` | `false` | `true` on Vista and Vision Pro |
| `RelativeZOnly` | `false` | `true` on Vision |
| `StartGCode` / `EndGCode` | see [04](04-mcode-dictionary.md) | |
| `Macro0..5_Label` / `_Content` | six macro buttons | |
| `rotaryAxis` | `3` | **Rotary config lives in the device profile** on GRBL devices |
| `rotarySteps` | `360` | |
| `rotaryDiameter` | `86` | |
| `rotaryIsChuck` | `true` | |
| `rotaryMode` | `false` | Rotary off by default |
| `Sim_MaxSpeedX` / `Y` | `500` / `400` | Preview simulation only |
| `Sim_MaxAccelX` / `Y` | `3000` | |
| `AirAssistM7` | `false` | |
| `EnableGrblJCommand` | `false` | |
| `ForceSValueOutput` | `false` | |
| `GCodeClustering` | `false` | Worth testing for fill throughput |
| `LastMachineFilePath` | `"C:/Users/ckr-pc/Desktop"` | **Vendor leftover** — WeCreat shipped their own build machine's path |
| `DockState_*` | | UI layout, harmless |

### Hygiene rules for profiles in this repo

The vendor files are visibly dumped from a working install and never cleaned. Ours must be
clean, because a profile is a public artifact:

- `CommPort` → `"(Choose)"`, never a hard-coded COM number
- `LastMachineFilePath`, `LastDevLibraryPath` → `""`
- `DisplayName` → the real name, not `"WeCreat Lumos (3) (1) (1)"`
- `Info` → `""`
- Unique `GUID` per profile
- `StartGCode` / `EndGCode` / macros → **empty**, until verified on hardware
- `EnableZ` → `false` until verified

## Related formats

| Extension | What it is |
|---|---|
| `.lbdev` | Device profile(s). **Import-only** in 2.x |
| `.lbzip` | **User Bundle** — settings, hotkeys, material test presets, image presets, devices, material libraries, art libraries. `File → Bundles → Export/Import Bundle`, or drag the file into LightBurn. *Not* project files |
| `.lbvendor` | Vendor Bundle — like a User Bundle plus banner image, device icon, vendor name/about/website/support fields, and (2.1) Vendor Menus |
| `.lbset` | **Controller firmware settings** dump from Machine Settings. Not a device profile |
| `.lbprefs` | Exported application preferences |
| `prefs.ini` | LightBurn's live preferences. Despite the extension **it is JSON**, and its `DeviceList` array has exactly the same shape as a `.lbdev` |

That last point is genuinely useful, and it is the practical way to learn what LightBurn actually
writes: **a `.lbdev` is effectively the `DeviceList` slice of `prefs.ini` written to its own
file.** So to discover the real key names for any device configuration — including ones the
documentation does not describe — build the device in LightBurn's wizard and then read your own
`prefs.ini`, rather than trying to export it.

> **You cannot export a `.lbdev` from LightBurn 2.x.** The Devices window's Export button
> produces a `.lbzip` User Bundle. `.lbdev` is import-only. If you are trying to capture a device
> configuration, either export the `.lbzip` (it is a zip — the device JSON is inside) or just copy
> `prefs.ini`. `tools/test-machine.ps1` menu option `p` does the latter automatically.
>
> **`prefs.ini` is your entire LightBurn configuration** — every device, path and preference. This
> repository gitignores it and publishes only extracted key names.

On Windows, LightBurn's preferences folder for recent builds is
`%LOCALAPPDATA%\LightBurn\` (containing `prefs.ini`, `backup/`, `themes/`). Use
**File → Preferences → Open Prefs Folder** to be certain.

## Distribution plan for this project

Ship `.lbdev` files in `profiles/draft/` for review and diffing — they are plain JSON and behave
well in git. Once profiles are confirmed on hardware, also publish a single
`WeCreat-Lumos-Ultra.lbzip` User Bundle carrying all profiles plus per-source material libraries,
so users import once.
