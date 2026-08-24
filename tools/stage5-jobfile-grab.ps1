# stage5-jobfile-grab.ps1
# Stage 5: fetch the G-code the machine actually ran, straight off the controller.
#
# READ-ONLY. HTTP GET requests only, against the file listing on port 8082. Sends no
# commands, writes nothing to the machine. Nothing fires. Nothing moves.
#
# WHY THIS IS THE IMPORTANT ONE
# After MakeIt sends a job, the complete G-code for that job is stored on the device and
# can simply be read. That is the whole M-code dictionary - source select, pulse width,
# focus, rotary - without Wireshark, without a bridge, and without sending a single
# unknown command to the machine.
#
# NOTE: /etc/mbtc/print.json names /mnt/SDCARD/curve/print_data.gcode, but on the shipping
# Ultra firmware that path 404s and the real directory is /mnt/SDCARD/printing/. The config
# is stale, so this script DISCOVERS the files rather than trusting it.
#
# BEFORE YOU START - THE CONTROL-MODE LATCH
# If anything has opened the machine's COM port since it was last powered on (Stage 1, a
# terminal, or LightBurn), MakeIt no longer has control and cannot run a job. POWER-CYCLE
# THE MACHINE first, then reconnect MakeIt.
#
# HOW TO USE IT
#   1. Power-cycle the machine if anything has touched the COM port.
#   2. In MakeIt, set up a SMALL job (a 10 mm square is plenty) and run it.
#   3. Run this with a label describing the job.
#   4. Change EXACTLY ONE setting, run the job again, grab again with a different label,
#      and diff the two.  e.g.  -Label uv-square   then   -Label mopa-square
#
# Usage:
#   .\tools\stage5-jobfile-grab.ps1 -Label "uv-square"
#   .\tools\stage5-jobfile-grab.ps1 -Target 192.168.42.1 -Label mopa-pw200 -MaxDepth 4

param(
  [string] $Target,
  [int]    $Port = 8082,
  [string] $Label = '',
  [int]    $MaxDepth = 4,
  [int]    $MaxDirs = 80,
  [int]    $MaxFileBytes = 4000000,
  [int]    $HeadBytes = 131072,     # for an oversized file, take this much of the head
  [int]    $TimeoutSec = 30,
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

# ------------------------------------------------------------------ discover
function Get-Links($path) {
  try {
    $r = Invoke-WebRequest -Uri ($base + $path) -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    $html = [string]$r.Content
    if ($r.Content -is [byte[]]) { $html = [System.Text.Encoding]::UTF8.GetString($r.Content) }
    $out = @()
    foreach ($m in [regex]::Matches($html, 'href\s*=\s*"([^"]+)"')) {
      $h = $m.Groups[1].Value
      # skip the listing UI's own anchors and parent links
      if ($h -eq '#' -or $h -eq '../' -or $h -eq '..' -or $h -eq '/' -or $h.StartsWith('?')) { continue }
      $out += $h
    }
    return ,$out
  } catch {
    Say ('    ' + $path + '   FAILED: ' + $_.Exception.Message) 'DarkYellow'
    return ,@()
  }
}

Say ''
Say '  === Discovering files under the job storage ===' 'Cyan'

$roots = @('/mnt/SDCARD/', '/mnt/UDISK/', '/mnt/exUDISK/')
$queue = New-Object System.Collections.Queue
foreach ($r in $roots) { $queue.Enqueue(@{ path = $r; depth = 0 }) }
$seen = @{}
$files = @()
$dirs = 0

while ($queue.Count -gt 0 -and $dirs -lt $MaxDirs) {
  $it = $queue.Dequeue()
  if ($seen.ContainsKey($it.path)) { continue }
  $seen[$it.path] = $true
  $dirs++

  $links = Get-Links $it.path
  if ($links.Count -eq 0) { Say ('  [dir] ' + $it.path + '   (empty)') 'DarkGray'; continue }
  Say ('  [dir] ' + $it.path + '   (' + $links.Count + ')') 'White'

  foreach ($h in $links) {
    $child = if ($h.StartsWith('/')) { $h } else { ($it.path.TrimEnd('/') + '/' + $h) }
    if ($h.EndsWith('/')) {
      Say ('          <dir>  ' + $h)
      if ($it.depth -lt $MaxDepth) { $queue.Enqueue(@{ path = $child; depth = $it.depth + 1 }) }
    } else {
      $files += $child
      $isJob = $h -match '(?i)\.(gcode|nc|gc|json|txt|cfg|ini)$'
      Say (('          ' + $(if ($isJob) { 'FILE*  ' } else { 'file   ' }) + $h)) $(if ($isJob) { 'Cyan' } else { 'DarkGray' })
    }
  }
}

$jobFiles = @($files | Where-Object { $_ -match '(?i)\.(gcode|nc|gc)$' })
$cfgFiles = @($files | Where-Object { $_ -match '(?i)\.(json|txt|cfg|ini)$' })

Say ''
Say ('  Found ' + $jobFiles.Count + ' G-code file(s) and ' + $cfgFiles.Count + ' config file(s)') 'Cyan'
if ($jobFiles.Count -eq 0) {
  Say ''
  Say '  NO G-CODE FOUND. Most likely one of:' 'Red'
  Say '    - MakeIt has not run a job since the machine was last powered on' 'Red'
  Say '    - the machine is latched into LightBurn control, so MakeIt could not send one' 'Red'
  Say '      (power-cycle the machine, reconnect MakeIt, run a job, then re-run this)' 'Red'
}

# ------------------------------------------------------------------ fetch and analyse
# Download with a HARD byte cap, enforced WHILE reading rather than after.
# Invoke-WebRequest buffers the entire response in memory before you can inspect it,
# so a runaway or endless file will consume RAM until it is killed. This streams and
# aborts the moment the cap is exceeded.
function Get-Capped($url, $cap) {
  $req = [System.Net.HttpWebRequest]::Create($url)
  $req.Timeout = $TimeoutSec * 1000
  $req.ReadWriteTimeout = $TimeoutSec * 1000
  $resp = $null; $stream = $null
  try {
    $resp = $req.GetResponse()

    # If the server declares a length, refuse before reading a single byte.
    $declared = -1
    try { $declared = [int64]$resp.ContentLength } catch {}

    # A real print job can be hundreds of megabytes, but everything we need - the
    # preamble with the mode, source and parameter codes - is in the first few KB.
    # So for an oversized file we take the HEAD of it and stop, rather than skipping
    # it entirely or dragging the whole thing into RAM.
    $stream = $resp.GetResponseStream()
    $ms  = New-Object System.IO.MemoryStream
    $buf = New-Object byte[] 65536
    $total = 0
    $partial = $false
    while ($true) {
      $n = $stream.Read($buf, 0, $buf.Length)
      if ($n -le 0) { break }
      $ms.Write($buf, 0, $n)
      $total += $n
      if ($total -ge $HeadBytes -and ($declared -gt $cap -or $total -gt $cap)) { $partial = $true; break }
    }
    return @{ tooBig = $false; partial = $partial; declared = $(if ($declared -ge 0) { $declared } else { $total }); bytes = $ms.ToArray() }
  } finally {
    if ($stream) { $stream.Dispose() }
    if ($resp)   { $resp.Close() }
  }
}

function Grab($path, $analyse) {
  Say ''
  Say ('  =================== ' + $path + ' ===================') 'White'
  try {
    $res = Get-Capped ($base + $path) $MaxFileBytes
    $bytes = $res.bytes
    if (-not $bytes -or $bytes.Length -eq 0) { Say '  empty response' 'DarkYellow'; return }
    if ($res.partial) {
      Say ('  FILE IS ' + $res.declared + ' BYTES - fetched the first ' + $bytes.Length + ' only.') 'DarkYellow'
      Say '  The preamble is what matters; the rest is bulk geometry.' 'DarkGray'
    }

    $safe = ($path.TrimStart('/') -replace '[\\/:*?"<>|]', '_')
    [System.IO.File]::WriteAllBytes((Join-Path $outDir $safe), $bytes)

    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $lines = $text -split "`r?`n"
    Say ('  ' + $bytes.Length + ' bytes, ' + $lines.Count + ' lines   -> ' + $safe) 'Green'

    if (-not $analyse) {
      $show = if ($text.Length -gt 1200) { $text.Substring(0, 1200) + ' ...[truncated]' } else { $text }
      foreach ($l in ($show -split "`r?`n")) { Say ('      ' + $l) 'Green' }
      return
    }

    Say ''
    Say '  --- every distinct G/M code, with a real example line ---' 'Cyan'
    $codes = @{}
    foreach ($l in $lines) {
      foreach ($m in [regex]::Matches($l, '(?i)\b([GM]\d{1,3})\b')) {
        $k = $m.Groups[1].Value.ToUpper()
        if ($codes.ContainsKey($k)) { $codes[$k]++ } else { $codes[$k] = 1 }
      }
    }
    foreach ($k in ($codes.Keys | Sort-Object)) {
      $ex = ($lines | Where-Object { $_ -match ('(?i)\b' + [regex]::Escape($k) + '\b') } | Select-Object -First 1)
      Say ('    {0,-6} x{1,-8} e.g.  {2}' -f $k, $codes[$k], $ex.Trim()) 'Green'
    }

    Say ''
    Say '  --- first 40 lines ---' 'Cyan'
    foreach ($l in ($lines | Select-Object -First 40)) { Say ('    ' + $l) }
    Say ''
    Say '  --- last 15 lines ---' 'Cyan'
    foreach ($l in ($lines | Select-Object -Last 15)) { Say ('    ' + $l) }
  } catch {
    Say ('  FAILED: ' + $_.Exception.Message) 'DarkYellow'
  }
}

# Save the transcript after every grab, so an interrupt never loses what was already
# captured. The G-code is the valuable part and it comes first.
$fileName = "stage5-jobgcode-$slug-$($hostName.ToLower())-$stamp.txt"
function Save-Log {
  foreach ($d in @((Join-Path $repo 'captures'), $(if ($SharePath) { Join-Path $SharePath 'captures' } else { $null }))) {
    if (-not $d) { continue }
    try {
      if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null }
      Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop
    } catch {}
  }
}

foreach ($f in ($jobFiles | Select-Object -First 6))  { Grab $f $true;  Save-Log }
Say ''
Say '  === G-code captured. Now sampling config files. ===' 'Cyan'
Say '  (Safe to Ctrl+C from here - the G-code above is already saved.)' 'DarkGray'
Save-Log
foreach ($f in ($cfgFiles | Select-Object -First 15)) { Grab $f $false; Save-Log }

# ------------------------------------------------------------------ save
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
    Write-Host ('  Mirrored files to ' + $sd) -ForegroundColor Green
  } catch {}
}

$written = @($written | Select-Object -Unique)
Write-Host ''
Write-Host '  ------------------------------------------------------------------'
if ($written.Count -eq 0) { Write-Host '  NOTHING SAVED' -ForegroundColor Red }
foreach ($w in $written) { Write-Host ('  Saved : ' + $w) -ForegroundColor Green }
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Read-Host '  Press Enter to close'
