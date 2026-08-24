# reference/ — local working area (gitignored)

Nothing in this folder is committed except this README and the scripts that populate it.

It holds material that belongs to WeCreat and is **not ours to redistribute**:

- `vendor-lbdev/` — WeCreat's official LightBurn profiles, downloaded from their public CDN by
  `../tools/fetch-vendor-lbdev.ps1`. Used as a structural reference for how WeCreat configures a
  LightBurn device.
- `makeit-extract/` — anything pulled out of a locally installed MakeIt! for interoperability
  analysis (see [../docs/11-makeit-internals.md](../docs/11-makeit-internals.md)).

## Populate it

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\fetch-vendor-lbdev.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ..\tools\summarize-lbdev.ps1 .\vendor-lbdev
```

## Why the separation matters

The *findings* from this material — the M-code dictionary, the work-mode list, the USB hardware
IDs, the `.lbdev` schema — are facts about an interface, and they live in `docs/`. The material
itself stays here, on your machine, and is never pushed.

Please keep it that way. A project that gets a takedown notice helps nobody.
