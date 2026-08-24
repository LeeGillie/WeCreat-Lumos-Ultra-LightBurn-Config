# validate-lbdev.ps1
# Checks every .lbdev in profiles/ against this project's hygiene and safety rules.
# Exit code 0 = clean, 1 = problems found. Suitable for CI.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate-lbdev.ps1 [path]

param([string]$Path)

$root = Split-Path $PSScriptRoot -Parent
if (-not $Path) { $Path = Join-Path $root 'profiles' }

$files = Get-ChildItem $Path -Filter *.lbdev -Recurse -ErrorAction SilentlyContinue
if (-not $files) { Write-Output ('No .lbdev files found under ' + $Path); exit 0 }

$problems = 0
$guids = @{}

foreach ($f in $files) {
  $issues = @()
  try { $j = Get-Content $f.FullName -Raw | ConvertFrom-Json }
  catch { Write-Output ('FAIL  {0}: not valid JSON - {1}' -f $f.Name, $_.Exception.Message); $problems++; continue }

  if (-not $j.DeviceList) { $issues += 'no DeviceList array' }

  foreach ($d in $j.DeviceList) {
    $s = $d.Settings

    # --- identity ---
    if (-not $d.DisplayName)                       { $issues += 'DisplayName is empty' }
    if ($d.DisplayName -match '\(\d+\)')           { $issues += ('DisplayName looks like a duplicate artifact: "' + $d.DisplayName + '"') }
    if (-not $d.GUID)                              { $issues += 'GUID is empty' }
    elseif ($guids.ContainsKey($d.GUID))           { $issues += ('GUID collides with ' + $guids[$d.GUID]) }
    else                                           { $guids[$d.GUID] = $f.Name }

    # --- no local leftovers ---
    if ($s.CommPort -and $s.CommPort -match '^COM\d+$') { $issues += ('CommPort is hard-coded to ' + $s.CommPort + ' - use "(Choose)"') }
    if ($s.LastMachineFilePath)                    { $issues += ('LastMachineFilePath leaks a local path: ' + $s.LastMachineFilePath) }
    if ($s.LastDevLibraryPath)                     { $issues += ('LastDevLibraryPath leaks a local path: ' + $s.LastDevLibraryPath) }
    if ($d.Info)                                   { $issues += 'Info should be empty' }

    # --- safety ---
    if ($s.StartGCode)                             { $issues += 'StartGCode is NOT empty - unverified M-codes must not ship (see SAFETY.md)' }
    if ($s.EndGCode)                               { $issues += 'EndGCode is NOT empty - unverified M-codes must not ship (see SAFETY.md)' }
    0..5 | ForEach-Object {
      if ($s."Macro${_}_Content" -and $s."Macro${_}_Content".Trim()) { $issues += ("Macro$_ has content - unverified M-codes must not ship") }
    }
    if ($s.EnableZ -eq $true)                      { $issues += 'EnableZ is true - Z behaviour is unverified on the Ultra' }
    if (-not $d.Checklist)                         { $issues += 'no start-of-job Checklist (required by this project)' }
    if ($s.Checklist -ne $true)                    { $issues += 'Settings.Checklist is not true - the checklist would not be shown' }

    # --- plausibility ---
    if ($d.Width -le 0 -or $d.Height -le 0)        { $issues += 'Width/Height must be positive' }
    if ($d.Width -gt 1000 -or $d.Height -gt 1000)  { $issues += ('implausible workspace: ' + $d.Width + ' x ' + $d.Height) }
    if ($d.Name -ne 'GRBL')                        { $issues += ('driver Name is "' + $d.Name + '" - expected "GRBL" (see docs/01-architecture.md)') }
    if ($d.Type -ne 'Serial')                      { $issues += ('connection Type is "' + $d.Type + '" - expected "Serial"') }
  }

  if ($issues.Count -eq 0) {
    Write-Output ('OK    ' + $f.Name)
  } else {
    Write-Output ('FAIL  ' + $f.Name)
    foreach ($i in $issues) { Write-Output ('        - ' + $i) }
    $problems += $issues.Count
  }
}

Write-Output ''
if ($problems -eq 0) { Write-Output ('All ' + $files.Count + ' profile(s) clean.'); exit 0 }
else { Write-Output ($problems.ToString() + ' problem(s) found.'); exit 1 }
