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

    # --- device class: Custom GCode with the WeCreat flavor ---
    if ($d.Name -ne 'Custom GCode') {
      $issues += ('driver Name is "' + $d.Name + '" - expected "Custom GCode". LightBurn 2.1+ warns on anything else for a WeCreat machine')
    }
    if ($d.ProfilePath -ne 'Custom GCode')         { $issues += ('ProfilePath is "' + $d.ProfilePath + '" - expected "Custom GCode"') }
    if ($s.GCodeFlavor -ne 'wecreat')              { $issues += ('GCodeFlavor is "' + $s.GCodeFlavor + '" - expected "wecreat"') }
    if ($d.Type -ne 'Serial')                      { $issues += ('connection Type is "' + $d.Type + '" - expected "Serial"') }
    if ($s.BaudRate -ne 1000000)                   { $issues += ('BaudRate is ' + $s.BaudRate + ' - confirmed working value is 1000000') }
    if ($s.S_Scale -ne 1000)                       { $issues += ('S_Scale is ' + $s.S_Scale + ' - confirmed value is 1000 (M4S1000 in vendor G-code)') }

    # --- no local leftovers ---
    if ($s.CommPort -and $s.CommPort -match '^COM\d+$') { $issues += ('CommPort is hard-coded to ' + $s.CommPort) }
    if ($s.LastMachineFilePath)                    { $issues += ('LastMachineFilePath leaks a local path: ' + $s.LastMachineFilePath) }
    if ($s.LastDevLibraryPath -or $d.LastDevLibraryPath) { $issues += 'LastDevLibraryPath leaks a local path' }
    if ($d.Info)                                   { $issues += 'Info should be empty' }

    # --- safety ---
    # StartGCode: source select is REQUIRED (M18S0 = MOPA, M18S1 = UV). Without it the machine
    # streams a job and marks nothing at any power - CONFIRMED-hardware 2026-08-25.
    # The no-blind-M-codes rule still stands, so this is a whitelist, not an open door: only
    # codes actually confirmed on hardware are permitted here.
    $allowedStart = @('', 'M18S0', 'M18S1')
    if ($allowedStart -notcontains ([string]$s.StartGCode).Trim()) {
      $issues += ("StartGCode '{0}' is not on the confirmed-on-hardware whitelist ({1}) - see docs/04-mcode-dictionary.md" -f $s.StartGCode, ($allowedStart -join ', '))
    }
    if ($s.EndGCode)                               { $issues += 'EndGCode is NOT empty - emitting M-codes from LightBurn is still untested' }
    if ($d.Macros -and @($d.Macros).Count -gt 0)   { $issues += 'Macros are populated - emitting M-codes from LightBurn is still untested' }
    if ($d.HomeOnStartup -eq $true)                { $issues += 'HomeOnStartup is true - homing is unverified, and Pn:Z reads asserted at rest' }
    if (-not $d.Checklist)                         { $issues += 'no start-of-job Checklist (required by this project)' }

    # --- plausibility ---
    if ($d.Width -le 0 -or $d.Height -le 0)        { $issues += 'Width/Height must be positive' }
    if ($d.Width -gt 1000 -or $d.Height -gt 1000)  { $issues += ('implausible workspace: ' + $d.Width + ' x ' + $d.Height) }
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
