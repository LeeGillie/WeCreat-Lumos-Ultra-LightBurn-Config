# summarize-lbdev.ps1
# Prints the interesting fields of any LightBurn .lbdev file(s) in human-readable form.
# Handles both device classes - "Custom GCode" (what this project ships) and "GRBL" (what
# WeCreat's own older profiles use) - since their Settings key sets are quite different.
#
# Usage:
#   .\tools\summarize-lbdev.ps1                          # summarizes profiles\draft
#   .\tools\summarize-lbdev.ps1 .\reference\vendor-lbdev # or any folder
#   .\tools\summarize-lbdev.ps1 .\some\file.lbdev        # or a single file

param([string]$Path)

$root = Split-Path $PSScriptRoot -Parent
if (-not $Path) { $Path = Join-Path $root 'profiles\draft' }

$targets = @()
if (Test-Path $Path -PathType Container) { $targets = Get-ChildItem $Path -Filter *.lbdev }
elseif (Test-Path $Path)                 { $targets = @(Get-Item $Path) }
else { Write-Output ('Not found: ' + $Path); exit 1 }

if ($targets.Count -eq 0) { Write-Output ('No .lbdev files in ' + $Path); exit 0 }

foreach ($file in $targets) {
  $j = Get-Content $file.FullName -Raw | ConvertFrom-Json
  foreach ($d in $j.DeviceList) {
    $s = $d.Settings
    $isCustom = ($d.Name -eq 'Custom GCode')

    Write-Output ('=== {0}' -f $file.Name)
    Write-Output ('    DisplayName : {0}' -f $d.DisplayName)
    Write-Output ('    Device      : Name={0}  Type={1}  GUID={2}' -f $d.Name, $d.Type, $d.GUID)
    if ($isCustom) {
      Write-Output ('    Flavor      : {0}' -f $(if ($s.GCodeFlavor) { $s.GCodeFlavor } else { '(none - LightBurn will warn on a WeCreat machine)' }))
    }
    Write-Output ('    Workspace   : {0} x {1} mm   MirrorX={2} MirrorY={3}' -f $d.Width, $d.Height, $d.MirrorX, $d.MirrorY)
    Write-Output ('    Serial      : baud={0}  S_Scale={1}' -f $s.BaudRate, $s.S_Scale)
    Write-Output ('    Homing      : HomeOnStartup={0}' -f $d.HomeOnStartup)

    if ($isCustom) {
      Write-Output ('    Comms       : AllowComms={0}  TargetBufferSize={1}  VariableLaserPower={2}' -f $s.AllowComms, $s.TargetBufferSize, $s.VariableLaserPower)
      Write-Output ('    Units       : Units={0}  ControlUnits={1}  DwellIsMilliseconds={2}' -f $s.Units, $s.ControlUnits, $s.DwellIsMilliseconds)
    } else {
      Write-Output ('    GRBL only   : CutOrigin={0}  EnableZ={1}  rotaryAxis={2} steps={3} dia={4}' -f $s.CutOrigin, $s.EnableZ, $s.rotaryAxis, $s.rotarySteps, $s.rotaryDiameter)
      Write-Output ('    Port        : {0}' -f $s.CommPort)
    }

    Write-Output ('    Camera      : {0}' -f $(if ($d.LastCamera) { $d.LastCamera } else { '(none)' }))

    $sg = if ($s.StartGCode) { ($s.StartGCode -replace "`r?`n", ' | ') } else { '(empty)' }
    $eg = if ($s.EndGCode)   { ($s.EndGCode   -replace "`r?`n", ' | ') } else { '(empty)' }
    Write-Output ('    StartGCode  : {0}' -f $sg)
    Write-Output ('    EndGCode    : {0}' -f $eg)

    # LightBurn 2.x stores macros as an array of {Label, Content}; older files used Macro0_*
    $macroLines = @()
    if ($d.Macros -and @($d.Macros).Count -gt 0) {
      $i = 0
      foreach ($m in $d.Macros) {
        if ($m.Label -and $m.Label.Trim()) { $macroLines += ('       [{0}] {1,-18} = {2}' -f $i, $m.Label, ($m.Content -replace "`r?`n", ' | ')) }
        $i++
      }
    } else {
      0..5 | ForEach-Object {
        $lbl = $s."Macro${_}_Label"; $con = $s."Macro${_}_Content"
        if ($lbl -and $lbl.Trim()) { $macroLines += ('       [{0}] {1,-18} = {2}' -f $_, $lbl, ($con -replace "`r?`n", ' | ')) }
      }
    }
    if ($macroLines.Count -gt 0) { Write-Output '    Macros      :'; $macroLines | ForEach-Object { Write-Output $_ } }
    else { Write-Output '    Macros      : (none)' }

    if ($d.Checklist) {
      Write-Output '    Checklist   :'
      foreach ($line in ($d.Checklist -split "`r?`n")) { if ($line.Trim()) { Write-Output ('       ' + $line) } }
    } else {
      Write-Output '    Checklist   : (none)  <-- profiles in this repo should have one'
    }
    Write-Output ''
  }
}
