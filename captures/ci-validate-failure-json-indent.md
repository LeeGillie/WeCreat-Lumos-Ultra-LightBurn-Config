# CI: `Validate / Profiles are valid, clean and safe` failed on every push

**Date:** 2026-08-27
**Status:** CONFIRMED — reproduced away from the runner, fix verified in both directions
**Affected runs:** every push since the workflow was added — 080d862, 17eefde, 72397ed,
e0f52c0, b930f29, 151d625, 43cb91e, c089f37, fd1a970, 70d0060, b995fbe, 1ff3cc4

## Symptom

One job of three fails, in 12–26 seconds, on every commit. The other two
("No vendor material committed", "Internal doc links resolve") pass. The
failing step is:

```
- name: Fail if the committed profiles drifted from the spec
  shell: pwsh
  run: |
    $diff = git status --porcelain profiles/
    if ($diff) { ...; exit 1 }
```

Meanwhile `./tools/validate-lbdev.ps1` run locally reports
`All 6 profile(s) clean.` — so nothing is actually wrong with the profiles.

## Cause

`tools/build-profiles.ps1` serialises with `ConvertTo-Json`, and the two
PowerShell hosts indent differently. Same script, same spec, same six files —
different bytes:

```
Windows PowerShell 5.1 (local, Lee's box)
{
        "DeviceList":  [
                                              {
                                                      "Checklist":  "=== ...
                                                      "CustomAlarmCodes":  {

                                                                                },

PowerShell 7 / pwsh (GitHub Actions, `shell: pwsh`)
{
    "DeviceList": [
        {
            "Checklist": "=== ...
            "CustomAlarmCodes": {},
```

Note both differences: the indentation width, and the way an empty object is
emitted (`{` newline newline `}` in 5.1 vs `{},` in 7). Line *counts* differ,
not just leading whitespace, so this cannot be repaired by re-indenting.

Round-tripping both files through one parser confirms they are the same
document:

```
$ diff <(python3 -c "...json.dumps(json.load(open(committed)),indent=1,sort_keys=True)") \
       <(python3 -c "...json.dumps(json.load(open(regenerated)),indent=1,sort_keys=True)")
SEMANTICALLY IDENTICAL — whitespace only
```

So: profiles are generated on a 5.1 box and committed; CI regenerates them
under `pwsh` 7; `git status --porcelain profiles/` sees six modified files;
the step exits 1. It would have failed on *every* push regardless of content.

The `2 annotations` in the notification email is not two errors — the two
passing jobs each carry 1 annotation too. Failed job = the same baseline
annotation plus one error.

## Fix

Compare **content**, not bytes. The drift step now round-trips both the
committed blob and the freshly generated file through the runner's own
serialiser before comparing, so formatting is normalised out and only real
drift is reported:

```powershell
$files = @(git ls-files profiles | Where-Object { $_ -like '*.lbdev' })
foreach ($f in $files) {
  $committed = (git show "HEAD:$f") -join "`n"
  $generated = Get-Content -LiteralPath $f -Raw
  $a = $committed | ConvertFrom-Json | ConvertTo-Json -Depth 20
  $b = $generated | ConvertFrom-Json | ConvertTo-Json -Depth 20
  if ($a -ne $b) { $drift += $f }
}
```

This also means a contributor may use either PowerShell host locally without
tripping CI — which the old byte check would have punished.

## Verification

Reproduced in a Linux container with PowerShell 7.4.6 against a git repo whose
HEAD held the 5.1-formatted profiles:

| case | expected | result |
|---|---|---|
| regenerate under pwsh 7, no spec change | pass | `profiles/ matches the spec (6 file(s) compared).` exit 0 |
| flip `mirrorY` in `profile-spec.json`, regenerate | fail | all 6 listed as drifted, exit 1 |

So the check still catches real drift; it no longer fires on formatting.

## Note

`.github/workflows/` is write-protected against remote tooling, so the
replacement `validate.yml` was handed over as a file and dropped in by hand.
