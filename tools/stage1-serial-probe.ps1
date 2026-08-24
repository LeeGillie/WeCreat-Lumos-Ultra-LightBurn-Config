# stage1-serial-probe.ps1
# Stage 1: talk to the laser's serial port directly, before involving LightBurn,
# so we see the raw firmware banner and settings rather than LightBurn's interpretation.
#
# READ-ONLY. Sends ONLY GRBL query commands ($$ $I $# $G and the realtime '?').
# It sends NO M-codes and NO motion commands. Nothing fires. Nothing moves.
#
# Requires nothing but Windows PowerShell - no Python, no PuTTY.
#
# Usage:
#   .\tools\stage1-serial-probe.ps1                       # auto-detect port, 1000000 baud
#   .\tools\stage1-serial-probe.ps1 -Port COM7
#   .\tools\stage1-serial-probe.ps1 -Port COM7 -Baud 500000
#   .\tools\stage1-serial-probe.ps1 -AllBauds             # try each known baud in turn
#
# IMPORTANT: close WeCreat MakeIt completely first - it holds the port.

param(
  [string]   $Port,
  [int]      $Baud = 1000000,
  [switch]   $AllBauds,
  [int]      $ReadMs = 1500,
  [switch]   $IncludeM27      # opt-in, see the warning below
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path $PSScriptRoot -Parent
$hostName = $env:COMPUTERNAME
if (-not $hostName) { try { $hostName = (Get-CimInstance Win32_ComputerSystem).Name } catch { $hostName = 'unknown' } }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = New-Object System.Text.StringBuilder

function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; [void]$log.AppendLine($t) }

Say ''
Say '  Stage 1 - serial identity probe (READ-ONLY, no beam, no motion)' 'Cyan'
Say ("  host: $hostName    " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Say ''

# ---------------------------------------------------------------- find the port
if (-not $Port) {
  $cand = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -match '\(COM\d+\)' -and $_.Name -notmatch 'Bluetooth' }
  if (-not $cand) { Say '  No non-Bluetooth COM port found. Is the laser on and MakeIt closed?' 'Red'; return }
  foreach ($c in $cand) {
    if ($c.Name -match '\((COM\d+)\)') {
      Say ('  found: ' + $c.Name)
      Say ('         ' + $c.DeviceID)
      if (-not $Port) { $Port = $Matches[1] }
    }
  }
  Say ("  using: $Port") 'Yellow'
}
Say ''

$bauds = if ($AllBauds) { @(1000000, 921600, 500000, 460800, 230400, 115200) } else { @($Baud) }

# ---------------------------------------------------------------- probe helper
function Probe-Port($portName, $baudRate) {
  Say ('===================== ' + $portName + ' @ ' + $baudRate + ' baud =====================') 'White'
  $sp = New-Object System.IO.Ports.SerialPort $portName, $baudRate, 'None', 8, 'One'
  # WeCreat's own LightBurn profiles set EnableDTR false. Toggling DTR/RTS resets many
  # GRBL boards, so leave both alone - we want to observe, not restart the controller.
  $sp.DtrEnable  = $false
  $sp.RtsEnable  = $false
  $sp.ReadTimeout  = 500
  $sp.WriteTimeout = 500
  $sp.NewLine = "`n"

  try { $sp.Open() }
  catch {
    Say ('  COULD NOT OPEN: ' + $_.Exception.Message) 'Red'
    Say '  If this says "Access to the port is denied", MakeIt or LightBurn still has it open.' 'Red'
    return $false
  }

  function Drain($ms) {
    $sb = New-Object System.Text.StringBuilder
    $deadline = (Get-Date).AddMilliseconds($ms)
    while ((Get-Date) -lt $deadline) {
      try { if ($sp.BytesToRead -gt 0) { [void]$sb.Append($sp.ReadExisting()) } else { Start-Sleep -Milliseconds 40 } }
      catch { Start-Sleep -Milliseconds 40 }
    }
    return $sb.ToString()
  }

  Say ''
  Say '  --- unsolicited output on open (banner window, 3s) ---' 'Yellow'
  $banner = Drain 3000
  if ($banner.Trim()) { foreach ($l in ($banner -split "`r?`n")) { if ($l.Trim()) { Say ('    ' + $l.TrimEnd()) 'Green' } } }
  else { Say '    (silence - the banner is usually only emitted on power-up/reset)' }

  $probes = @(
    @{ send = '?';   note = 'GRBL realtime status query';  raw = $true },
    @{ send = '$$';  note = 'settings dump - NEVER PUBLISHED for any WeCreat machine' },
    @{ send = '$I';  note = 'build info' },
    @{ send = '$#';  note = 'work coordinate offsets' },
    @{ send = '$G';  note = 'parser state' }
  )
  if ($IncludeM27) { $probes += @{ send = 'M27'; note = 'position report - INFERRED meaning, opt-in only' } }

  foreach ($p in $probes) {
    Say ''
    Say ('  --- ' + $p.send + '    (' + $p.note + ') ---') 'Yellow'
    try {
      if ($p.raw) { $sp.Write($p.send) } else { $sp.Write($p.send + "`n") }
    } catch { Say ('    write failed: ' + $_.Exception.Message) 'Red'; continue }
    $r = Drain $ReadMs
    if ($r.Trim()) { foreach ($l in ($r -split "`r?`n")) { if ($l.Trim()) { Say ('    ' + $l.TrimEnd()) 'Green' } } }
    else { Say '    (no response)' 'DarkYellow' }
  }

  Say ''
  $sp.Close(); $sp.Dispose()
  return $true
}

if ($IncludeM27) {
  Say ''
  Say '  !! -IncludeM27 was set. M27 is believed to be a position report on the Vision' 'Red'
  Say '     generation, but WeCreat renumbers M-codes between models and the Ultra is' 'Red'
  Say '     unverified. Ctrl+C now if you did not mean this.' 'Red'
  Start-Sleep -Seconds 4
}

foreach ($b in $bauds) {
  $ok = Probe-Port $Port $b
  if (-not $ok) { continue }
  if (-not $AllBauds) { break }
}

# ---------------------------------------------------------------- save
$fileName = "stage1-serial-$($hostName.ToLower())-$stamp.txt"
$written = @()
foreach ($dest in @((Join-Path $repo 'captures'))) {
  try {
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
    Set-Content -Path (Join-Path $dest $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop
    $written += (Join-Path $dest $fileName)
  } catch {}
}
# and back to the share it was cloned from, if we can find it
try {
  $origin = (& git -C $repo remote get-url origin 2>$null)
  if ($origin -and $origin.StartsWith('\\')) {
    $d = Join-Path $origin 'captures'
    if (Test-Path $d) { Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop; $written += (Join-Path $d $fileName) }
  }
} catch {}

Write-Host ''
Write-Host '  ------------------------------------------------------------------'
foreach ($w in $written) { Write-Host ('  Saved : ' + $w) }
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Write-Host '  The $$ output is the prize here - no WeCreat machine has ever had its'
Write-Host '  settings table published. $130/$131 give the real field size, $110/$111'
Write-Host '  the max rates, and $30 confirms the S-value scale.'
Write-Host ''
Read-Host '  Press Enter to close'
