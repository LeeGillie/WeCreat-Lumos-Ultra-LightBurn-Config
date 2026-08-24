# stage5-jobfile-grab.ps1
# Stage 5: fetch the G-code the machine actually ran, straight off the controller.
#
# READ-ONLY. HTTP GET requests only, against the file listing on port 8082. Sends no
# commands, writes nothing to the machine. Nothing fires. Nothing moves.
#
# WHY THIS IS THE IMPORTANT ONE
# /etc/mbtc/print.json on the controller names the files it executes:
#     framing_file : /mnt/SDCARD/framing/framing_data.gcode
#     print_file   : /mnt/SDCARD/curve/print_data.gcode
# So after MakeIt sends a job, the real, complete G-code for that job is sitting on
# the device and can simply be read. That is the whole M-code dictionary - source
# select, pulse width, focus, rotary, everything MakeIt can express - without
# Wireshark and without sending a single unknown command to the machine.
#
# BEFORE YOU START - THE CONTROL-MODE LATCH
# If anything has opened the machine's COM port since it was last powered on (Stage 1, a
# terminal, or LightBurn), MakeIt no longer has control and will say so. POWER-CYCLE THE
# MACHINE before step 1 below, or MakeIt will not be able to run the job.
#
# HOW TO USE IT
#   1. In MakeIt, set up a small job and run it (or frame it, for framing_data).
#   2. Run this. It grabs whatever is currently on the device.
#   3. Change EXACTLY ONE setting in MakeIt, run again, grab again, and diff.
#      Use -Label to keep the two apart, e.g. -Label uv  then  -Label mopa
#
# Usage:
#   .\tools\stage5-jobfile-grab.ps1 -Label "uv-10mm-square"
#   .\tools\stage5-jobfile-grab.ps1 -Target 192.168.42.1 -Label mopa-pw200

param(
  [string] $Target,
  [int]    $Port = 8082,
  [string] $Label = '',
  [int]    $TimeoutSec = 20,
  [string] $SharePath
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path $PSScriptRoot -Parent
$hostName = $env:COMPUTERNAME
if (-not $hostName) { try { $hostName = (Get-CimInstance Win32_ComputerSystem).Name } catch { $hostName = 'unknown' } }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$slug  = if ($Label) { ($Label -replace '[^\w\-]', '-') } else { 'job' }
$log = New-Object System.Text.StringBuilder
function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; [void]$log.AppendLine($t) }

Say ''
Say '  Stage 5 - fetch the job G-code off the controller (READ-ONLY)' 'Cyan'
Say ("  host: $hostName   label: '$slug'   " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Say ''

if (-not $Target) {
  $ifs = Get-NetAdapter -ErrorAction SilentlyContinue |
         Where-Object { $_.InterfaceDescription -match 'RNDIS|USB Ethernet|Remote NDIS' -and $_.Status -eq 'Up' }
  foreach ($i in $ifs) {
    $ip = Get-NetIPAddress -InterfaceIndex $i.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -notmatch '^169\.254\.' }
    foreach ($a in $ip) { $parts = $a.IPAddress -split '\.'; $Target = ($parts[0..2] -join '.') + '.1' }
  }
}
if (-not $Target) { Say '  No RNDIS link found. Is the laser connected and powered?' 'Red'; Read-Host '  Enter'; return }
$base = "http://${Target}:$Port"
Say ("  controller: $base") 'Yellow'

$outDir = Join-Path $repo ('captures\jobgcode-' + $slug + '-' + $stamp)
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# ------------------------------------------------------------------ list a few dirs
foreach ($d in @('/mnt/SDCARD/', '/mnt/SDCARD/curve/', '/mnt/SDCARD/framing/', '/mnt/UDISK/')) {
  Say ''
  Say ('  --- listing ' + $d) 'Yellow'
  try {
    $r = Invoke-WebRequest -Uri ($base + $d) -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    $html = [string]$r.Content
    if ($r.Content -is [byte[]]) { $html = [System.Text.Encoding]::UTF8.GetString($r.Content) }
    $n = 0
    foreach ($m in [regex]::Matches($html, 'href\s*=\s*"([^"]+)"')) {
      $h = $m.Groups[1].Value
      if ($h -eq '../' -or $h -eq '..' -or $h -eq '/') { continue }
      Say ('        ' + $h); $n++
    }
    if ($n -eq 0) { Say '        (empty)' 'DarkGray' }
  } catch { Say ('        FAILED: ' + $_.Exception.Message) 'DarkYellow' }
}

# ------------------------------------------------------------------ grab the job files
$targets = @(
  @{ path = '/mnt/SDCARD/curve/print_data.gcode';     name = 'print_data.gcode' },
  @{ path = '/mnt/SDCARD/framing/framing_data.gcode'; name = 'framing_data.gcode' }
)

foreach ($t in $targets) {
  Say ''
  Say ('  =================== ' + $t.path + ' ===================') 'White'
  try {
    $r = Invoke-WebRequest -Uri ($base + $t.path) -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    $bytes = $r.Content
    if ($bytes -isnot [byte[]]) { $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$bytes) }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $lines = $text -split "`r?`n"
    Say ('  ' + $bytes.Length + ' bytes, ' + $lines.Count + ' lines') 'Green'

    [System.IO.File]::WriteAllBytes((Join-Path $outDir $t.name), $bytes)

    # ---- the analysis that matters: which codes appear, and how often
    Say ''
    Say '  --- distinct G/M codes used ---' 'Cyan'
    $codes = @{}
    foreach ($l in $lines) {
      foreach ($m in [regex]::Matches($l, '(?i)\b([GM]\d{1,3})\b')) {
        $k = $m.Groups[1].Value.ToUpper()
        if ($codes.ContainsKey($k)) { $codes[$k]++ } else { $codes[$k] = 1 }
      }
    }
    foreach ($k in ($codes.Keys | Sort-Object { [int]($_ -replace '[GM]','') } | Sort-Object { $_.Substring(0,1) })) {
      # show one real example line for each code
      $ex = ($lines | Where-Object { $_ -match ('(?i)\b' + [regex]::Escape($k) + '\b') } | Select-Object -First 1)
      Say ('    {0,-6} x{1,-7} e.g.  {2}' -f $k, $codes[$k], $ex.Trim()) 'Green'
    }

    Say ''
    Say '  --- first 40 lines ---' 'Cyan'
    foreach ($l in ($lines | Select-Object -First 40)) { Say ('    ' + $l) }
    Say ''
    Say '  --- last 15 lines ---' 'Cyan'
    foreach ($l in ($lines | Select-Object -Last 15)) { Say ('    ' + $l) }
  } catch {
    Say ('  FAILED: ' + $_.Exception.Message) 'DarkYellow'
    Say '  (If this is 404, MakeIt may not have sent a job yet, or the paths differ on' 'DarkGray'
    Say '   your firmware. Check the listings above for the real filenames.)' 'DarkGray'
  }
}

# ------------------------------------------------------------------ save
$fileName = "stage5-jobgcode-$slug-$($hostName.ToLower())-$stamp.txt"
$written = @()
foreach ($d in @((Join-Path $repo 'captures'), $(if ($SharePath) { Join-Path $SharePath 'captures' } else { $null }))) {
  if (-not $d) { continue }
  try {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null }
    Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop
    $written += (Join-Path $d $fileName)
  } catch {}
}
if ($SharePath -and (Test-Path $outDir)) {
  try {
    $sd = Join-Path $SharePath ('captures\jobgcode-' + $slug + '-' + $stamp)
    New-Item -ItemType Directory -Force -Path $sd -ErrorAction Stop | Out-Null
    Copy-Item (Join-Path $outDir '*') $sd -Force -ErrorAction SilentlyContinue
    Write-Host ('  Mirrored G-code to ' + $sd) -ForegroundColor Green
  } catch {}
}

$written = @($written | Select-Object -Unique)
Write-Host ''
Write-Host '  ------------------------------------------------------------------'
if ($written.Count -eq 0) { Write-Host '  NOTHING SAVED' -ForegroundColor Red }
foreach ($w in $written) { Write-Host ('  Saved : ' + $w) -ForegroundColor Green }
Write-Host ('  G-code: ' + $outDir) -ForegroundColor Green
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Write-Host '  To build the M-code table: change ONE thing in MakeIt (UV vs MOPA, two'
Write-Host '  pulse widths, two focus heights, rotary on/off), re-run the job, grab'
Write-Host '  again with a different -Label, and diff the two files.'
Write-Host ''
Read-Host '  Press Enter to close'
