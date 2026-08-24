# 11 — MakeIt! Internals

What can and cannot be learned by inspecting a locally installed copy of WeCreat MakeIt!.

> **Purpose and scope.** Everything here is done for **interoperability** — determining the
> interface the operator's own hardware expects, so a LightBurn profile can be written for it.
> This repository publishes only the resulting **factual findings**. No WeCreat code, asset, or
> extracted file is redistributed. `reference/` is gitignored.

Findings below are from **MakeIt! 3.0.6** on Windows.

## Layout

```
C:\Program Files\WeCreat\makeit-builder\
    WeCreat MakeIt!.exe
    resources\
        app.asar                 ~417 MB   Electron application archive
        app-update.yml
    resource\
        driver\win\rndis\        RNDIS.inf, rndis11.inf, .cat files,
                                 usb-driver-installer-x64.exe / -x86.exe
    locales\  *.pak              Chromium locale bundles
```

It is an **Electron** application (Chromium `.pak` files, `app.asar`, `LICENSE.electron.txt`).

Inside `app.asar`:

```
packages/laser-builder/main/dist/index.jsc         873 KB   V8 bytecode (bytenode)
packages/laser-builder/main/dist/f.enc            ~41 MB   ENCRYPTED
packages/laser-builder/main/dist/opencv.js         ~8 MB
packages/laser-builder/preload/dist/index.jsc      336 KB   V8 bytecode
packages/laser-builder/renderer/dist/...                    assets, images, fonts, models
node_modules/...                                            ordinary dependencies
```

## Finding 1 — The application logic is protected

The renderer's JavaScript is **not present as `.js` in the archive**. The main and preload
bundles are compiled to **V8 bytecode** (`.jsc`, bytenode), and the bulk of the application is in
**`f.enc`, which is encrypted**.

We confirmed this by scanning the extracted `.jsc` files for machine vocabulary, G-code tokens
and HTTP endpoints. Results were empty — the only strings recovered were generic
(`http://localhost`, `http://127.0.0.1`, JSON-schema URLs, font names).

**Consequence: static analysis will not yield the Ultra's M-code table.** The machine definitions
are behind encryption. The practical route to the Ultra's protocol is therefore **live capture** —
Wireshark on the RNDIS interface while MakeIt runs a job, or the firmware tarball. See
[03-bringup-plan.md](03-bringup-plan.md) Stage 5.

This is worth stating plainly so nobody else burns a weekend on it.

## Finding 2 — The Ultra's work-mode list, from the vendor's own assets

The renderer's image tree is *not* encrypted, and it is organised per machine. MakeIt 3.0.6
contains a **`lumosUltraWorkMode/`** folder distinct from the generic `workMode/` folder:

```
renderer/dist/images/lumosUltraWorkMode/
    plane-mode.png
    cylinder-mode.png
    emboss-mode.png
    crystal-mode.png
    crystal-mode3D.png
    autoslider-mode.jpg
    autosliderCylinder-mode.jpg
    conveyorbelt-mode.png
    conveyorBeltSlide-mode.png

renderer/dist/images/lumosUltraTip/
    tip1.png  tip2.png  tip3.png  tip4.png
```

Compare the generic set, which additionally has `baseplate-mode`, `conveyor-mode`, `curve-mode`
and `manualhand-mode`.

**This is the authoritative Lumos Ultra mode inventory** — the vendor's own list for this
machine, not marketing copy. It is the basis of section C of
[02-feature-inventory.md](02-feature-inventory.md).

## Finding 3 — The updater points at a GitHub repository

`resources/app-update.yml`:

```yaml
owner: yuerugoutql
repo: makeit-builder
provider: github
updaterCacheDirName: makeit-builder-updater
```

MakeIt updates itself from a GitHub repository, `yuerugoutql/makeit-builder`. If that repository
is public, its **releases** would carry every MakeIt build — including older ones — and release
notes may name machines and features before the support-site changelog does. Worth checking; we
have not been able to confirm its visibility.

## Finding 4 — Version drift

The installed build is **3.0.6**. WeCreat's public "Software Version Information" changelog tops
out at **3.0.2**, and never mentions the Lumos Ultra at all. The shipping software is ahead of
the published changelog — so the changelog is not a reliable guide to what MakeIt supports.

## Reproducing this

`tools/asar-tool.js` is a dependency-free reader for Electron `.asar` archives:

```powershell
$node = 'C:\Program Files\nodejs\node.exe'
$asar = 'C:\Program Files\WeCreat\makeit-builder\resources\app.asar'

# what's inside
& $node .\tools\asar-tool.js list $asar
& $node .\tools\asar-tool.js list $asar "lumosUltra"

# pull one file out (into gitignored reference/)
& $node .\tools\asar-tool.js extract $asar "packages/laser-builder/main/dist/index.jsc" .\reference\makeit-extract\main-index.jsc

# search text-ish entries
& $node .\tools\asar-tool.js grep $asar "measure_distance"
```

`tools/scan-strings.js` pulls printable runs out of a binary and filters them by regex — used to
check whether the `.jsc` bundles carry recoverable strings.

## Still worth trying

1. **The Ultra's firmware tarball.** Ask WeCreat support for the Ultra OTA file, unpack it, and
   run `strings | grep -E "^M[0-9]+"`. This is the cheapest possible route to a real M-code table.
2. **Runtime interception.** The renderer must decrypt `f.enc` to run. Anyone comfortable with
   Electron debugging could recover the decrypted bundle at runtime on their own machine.
3. **`yuerugoutql/makeit-builder`** — check whether it is public.
4. **`opencv.js`** is unencrypted; it may reveal how camera calibration is applied, which is
   relevant to [08-cameras.md](08-cameras.md).
