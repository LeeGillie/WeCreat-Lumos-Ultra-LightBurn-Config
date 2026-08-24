# summarize-lbdev.ps1
# Prints the interesting fields of any LightBurn .lbdev file(s) in human-readable form.
# Works on vendor profiles, this project's drafts, or anything you exported yourself.
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
    Write-Output ('=== {0}' -f $file.Name)
    Write-Output ('    DisplayName : {0}' -f $d.DisplayName)
    Write-Output ('    Driver/Conn : Name={0}  Type={1}  GUID={2}' -f $d.Name, $d.Type, $d.GUID)
    Write-Output ('    Workspace   : {0} x {1} mm   MirrorX={2} MirrorY={3}  CutOrigin={4}' -f $d.Width, $d.Height, $d.MirrorX, $d.MirrorY, $s.CutOrigin)
    Write-Output ('    Offsets     : ({0},{1})  enabled={2}' -f $d.ProcessOffsetX, $d.ProcessOffsetY, $d.EnableProcessOffset)
    Write-Output ('    Serial      : port={0}  baud={1}  S_Scale={2}' -f $s.CommPort, $s.BaudRate, $s.S_Scale)
    Write-Output ('    Z / homing  : EnableZ={0}  RelativeZOnly={1}  HomeOnStartup={2}' -f $s.EnableZ, $s.RelativeZOnly, $d.HomeOnStartup)
    Write-Output ('    Rotary      : axis={0} steps={1} dia={2} chuck={3} enabled={4}' -f $s.rotaryAxis, $s.rotarySteps, $s.rotaryDiameter, $s.rotaryIsChuck, $s.rotaryMode)
    Write-Output ('    Camera      : {0}' -f $(if ($d.LastCamera) { $d.LastCamera } else { '(none)' }))

    $sg = if ($s.StartGCode) { ($s.StartGCode -replace "`r?`n", ' | ') } else { '(empty)' }
    $eg = if ($s.EndGCode)   { ($s.EndGCode   -replace "`r?`n", ' | ') } else { '(empty)' }
    Write-Output ('    StartGCode  : {0}' -f $sg)
    Write-Output ('    EndGCode    : {0}' -f $eg)

    $anyMacro = $false
    0..5 | ForEach-Object {
      $lbl = $s."Macro${_}_Label"; $con = $s."Macro${_}_Content"
      if ($lbl -and $lbl.Trim()) {
        if (-not $anyMacro) { Write-Output '    Macros      :'; $script:anyMacro = $true }
        Write-Output ('       [{0}] {1,-18} = {2}' -f $_, $lbl, ($con -replace "`r?`n", ' | '))
        $anyMacro = $true
      }
    }
    if (-not $anyMacro) { Write-Output '    Macros      : (none)' }

    if ($d.Checklist) {
      Write-Output '    Checklist   :'
      foreach ($line in ($d.Checklist -split "`r?`n")) { if ($line.Trim()) { Write-Output ('       ' + $line) } }
    } else {
      Write-Output '    Checklist   : (none)  <-- profiles in this repo should have one'
    }
    Write-Output ''
  }
}
