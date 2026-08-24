# benchy-bootstrap.ps1
# One-shot setup + Stage 0 for the machine that has the Lumos Ultra attached.
#
# Designed to be launched from a UNC path on a machine with no clipboard sharing,
# so the operator has to type as little as possible.
#
# It will:
#   1. copy or clone this repository to a local folder on the test machine
#   2. run the read-only workstation probe
#   3. write the result into captures/ BOTH locally and back on the share
#
# It fires nothing, moves nothing, and sends nothing to the laser.

$ErrorActionPreference = 'Continue'

$shareRepo = Split-Path $PSScriptRoot -Parent     # where this script was launched from
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$who = $env:COMPUTERNAME
if (-not $who) { try { $who = (Get-CimInstance Win32_ComputerSystem).Name } catch {} }
if (-not $who) { $who = 'unknown-host' }
$who = $who.ToLower()

Write-Host ''
Write-Host '  WeCreat Lumos Ultra - LightBurn project' -ForegroundColor Cyan
Write-Host '  Test machine bootstrap + Stage 0 (no beam, read-only)' -ForegroundColor Cyan
Write-Host ''
Write-Host ("  running on : $who")
Write-Host ("  source     : $shareRepo")
Write-Host ''

# ---------------------------------------------------------------- 1. local copy
$candidates = @('D:\Dev', 'D:\DevHome', 'C:\Dev', (Join-Path $env:USERPROFILE 'Dev'))
$parent = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $parent) { $parent = Join-Path $env:USERPROFILE 'Dev'; New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$local = Join-Path $parent 'WeCreat Lumos Ultra Lightburn Config'

Write-Host '  [1/3] Getting a local copy...' -ForegroundColor Yellow
if ($local.TrimEnd('\').ToLower() -eq $shareRepo.TrimEnd('\').ToLower()) {
  Write-Host '        already running from the local repo - nothing to copy'
} elseif (Test-Path (Join-Path $local '.git')) {
  Write-Host ("        already present at $local - pulling latest")
  Push-Location $local; & git pull 2>&1 | ForEach-Object { Write-Host ('        ' + $_) }; Pop-Location
} elseif (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Host ("        git clone -> $local")
  & git clone $shareRepo $local 2>&1 | ForEach-Object { Write-Host ('        ' + $_) }
} else {
  Write-Host '        git not found - falling back to a plain file copy'
  New-Item -ItemType Directory -Force -Path $local | Out-Null
  & robocopy $shareRepo $local /E /XD .git reference /NFL /NDL /NJH /NJS /NP | Out-Null
  Write-Host ("        copied to $local")
  Write-Host '        (install git later so you can commit captures: winget install Git.Git)'
}
if (-not (Test-Path $local)) { Write-Host '  FAILED to create a local copy. Check share access.' -ForegroundColor Red; Read-Host 'Enter to close'; exit 1 }

# ---------------------------------------------------------------- 2. probe
Write-Host ''
Write-Host '  [2/3] Probing this machine (read-only, no laser output)...' -ForegroundColor Yellow
Write-Host ''

$probe = Join-Path $local 'tools\probe-workstation.ps1'
if (-not (Test-Path $probe)) { $probe = Join-Path $shareRepo 'tools\probe-workstation.ps1' }
$result = & powershell -NoProfile -ExecutionPolicy Bypass -File $probe 2>&1 | Out-String

# ---------------------------------------------------------------- 3. save
$fileName = "stage0-usb-$who-$stamp.txt"
$written = @()
foreach ($dest in @((Join-Path $local 'captures'), (Join-Path $shareRepo 'captures'))) {
  try {
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
    Set-Content -Path (Join-Path $dest $fileName) -Value $result -Encoding UTF8 -ErrorAction Stop
    $written += (Join-Path $dest $fileName)
  } catch { Write-Host ('        could not write to ' + $dest) -ForegroundColor DarkYellow }
}

# ---------------------------------------------------------------- report
Write-Host '  [3/3] Result' -ForegroundColor Yellow
Write-Host ''
$lines = $result -split "`r?`n"
$show = $false
foreach ($l in $lines) {
  if ($l -match '^=== (4|5|9|10)\.') { $show = $true }
  elseif ($l -match '^=== ') { $show = $false }
  if ($show) {
    $c = 'Gray'
    if ($l -match '^\s*>>') { $c = 'Green' }
    if ($l -match 'No laser detected') { $c = 'Red' }
    if ($l -match '^=== ') { $c = 'White' }
    Write-Host ('  ' + $l) -ForegroundColor $c
  }
}

Write-Host ''
Write-Host '  ------------------------------------------------------------------'
Write-Host ('  Local repo : ' + $local)
foreach ($w in $written) { Write-Host ('  Saved      : ' + $w) }
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Write-Host '  The full capture is in the file(s) above - it includes every USB'
Write-Host '  VID/PID, which is what settles whether this machine is a GRBL'
Write-Host '  device or a real galvo controller.'
Write-Host ''
Write-Host '  If it says NO LASER DETECTED:'
Write-Host '    - is the Ultra powered on, not just plugged in?'
Write-Host '    - is WeCreat MakeIt fully closed? (check Task Manager - it holds the port)'
Write-Host '    - RNDIS driver installed? run:'
Write-Host '        ...\WeCreat\makeit-builder\resource\driver\win\rndis\usb-driver-installer-x64.exe'
Write-Host '    - try a USB port directly on the PC rather than through a hub'
Write-Host ''
Read-Host '  Press Enter to close'
