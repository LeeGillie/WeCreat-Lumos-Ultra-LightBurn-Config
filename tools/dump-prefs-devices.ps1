<#
  dump-prefs-devices.ps1

  Summarise the devices inside a LightBurn prefs.ini (or an .lbdev).

  Both are JSON with a top-level DeviceList array. This prints one row per
  device so you can see which profiles exist, which are duplicates, and - the
  reason this tool exists - WHICH DEVICE CLASS each one actually is.

  Note the key layout, which is easy to get wrong:
    device level  : Name, Type, Width, Height, MirrorX, MirrorY, HomeOnStartup
    Settings level: GCodeFlavor, BaudRate, S_Scale, CutOrigin

  Read-only. Touches nothing.

    .\dump-prefs-devices.ps1 -Path ..\captures\lightburn-prefs-benchy-*.ini
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $Path
)

$file = Get-Item -Path $Path -ErrorAction Stop | Select-Object -First 1
Write-Host "Reading: $($file.FullName)" -ForegroundColor Cyan
Write-Host ""

try {
  $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
} catch {
  Write-Host "Could not parse as JSON: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

if (-not $json.DeviceList) {
  Write-Host "No DeviceList found." -ForegroundColor Red
  exit 1
}

$i = -1
foreach ($d in $json.DeviceList) {
  $i++
  $s = $d.Settings

  Write-Host ("[{0}] {1}" -f $i, $d.DisplayName) -ForegroundColor Yellow

  $cls = "$($d.Name)"
  $colour = 'Gray'
  if ($cls -eq 'Custom GCode') { $colour = 'Green' }
  Write-Host ("      class       : {0}   (GCodeFlavor: {1})" -f $cls, $s.GCodeFlavor) -ForegroundColor $colour

  Write-Host ("      size        : {0} x {1}    Type: {2}" -f $d.Width, $d.Height, $d.Type)
  Write-Host ("      MirrorX/Y   : {0} / {1}" -f $d.MirrorX, $d.MirrorY)
  Write-Host ("      HomeOnStart : {0}" -f $d.HomeOnStartup)
  Write-Host ("      baud        : {0}    S_Scale: {1}    CutOrigin: {2}" -f $s.BaudRate, $s.S_Scale, $s.CutOrigin)
  Write-Host ""
}

Write-Host ("{0} device(s) total." -f ($i + 1)) -ForegroundColor Cyan
