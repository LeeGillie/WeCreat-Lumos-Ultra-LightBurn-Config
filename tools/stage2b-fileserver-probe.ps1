# stage2b-fileserver-probe.ps1
# Stage 2b: map the unauthenticated file listing the controller serves on port 8082.
#
# READ-ONLY. Issues HTTP GET requests only. Writes nothing to the machine, sends no
# commands, and never touches the control API on 8080. Nothing fires. Nothing moves.
#
# Why: the controller is a Linux SBC that exposes its filesystem over HTTP with no
# authentication. Machine definitions, calibration and configuration live there, and
# they are the most likely place to find what LightBurn cannot ask for - the real field
# size, the source-select command, and the per-model settings.
#
# Scope guards: bounded depth, bounded file count, small files only. This maps and
# samples; it does not mirror the device.
#
# Usage:
#   .\tools\stage2b-fileserver-probe.ps1
#   .\tools\stage2b-fileserver-probe.ps1 -Target 192.168.42.1 -MaxDepth 3

param(
  [string] $Target,
  [int]    $Port = 8082,
  [int]    $MaxDepth = 3,
  [int]    $MaxDirs = 120,
  [int]    $MaxFileBytes = 65536,
  [int]    $TimeoutSec = 6,
  [string] $SharePath
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path $PSScriptRoot -Parent
$hostName = $env:COMPUTERNAME
if (-not $hostName) { try { $hostName = (Get-CimInstance Win32_ComputerSystem).Name } catch { $hostName = 'unknown' } }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = New-Object System.Text.StringBuilder
function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; [void]$log.AppendLine($t) }

Say ''
Say '  Stage 2b - controller file listing (READ-ONLY, GET requests only)' 'Cyan'
Say ("  host: $hostName    " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
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
if (-not $Target) { Say '  No RNDIS link found. Is the laser connected and powered?' 'Red'; return }
Say ("  target: http://${Target}:$Port/") 'Yellow'
Say ''

$base = "http://${Target}:$Port"
$seen = @{}
$queue = New-Object System.Collections.Queue
$queue.Enqueue(@{ path = '/'; depth = 0 })
$dirCount = 0
$interesting = @()

# Names worth pulling the contents of. Config and machine definition, not media.
$interestingRe = '(?i)\.(json|ini|cfg|conf|xml|txt|yaml|yml|properties|gcode|nc|tab|csv|log)$|^(config|machine|param|setting|model|device|calib)'

while ($queue.Count -gt 0 -and $dirCount -lt $MaxDirs) {
  $item = $queue.Dequeue()
  $p = $item.path
  if ($seen.ContainsKey($p)) { continue }
  $seen[$p] = $true
  $dirCount++

  try {
    $r = Invoke-WebRequest -Uri ($base + $p) -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
  } catch {
    Say ('  [dir] ' + $p + '   FAILED: ' + $_.Exception.Message) 'DarkYellow'
    continue
  }

  $html = [string]$r.Content
  if ($r.Content -is [byte[]]) { $html = [System.Text.Encoding]::UTF8.GetString($r.Content) }

  $links = @()
  foreach ($m in [regex]::Matches($html, 'href\s*=\s*"([^"]+)"')) {
    $h = $m.Groups[1].Value
    if ($h -eq '../' -or $h -eq '..' -or $h -eq '/' -or $h.StartsWith('?')) { continue }
    $links += $h
  }

  Say ('  [dir] ' + $p + '   (' + $links.Count + ' entries)') 'White'

  foreach ($h in $links) {
    $child = if ($h.StartsWith('/')) { $h } else { ($p.TrimEnd('/') + '/' + $h) }
    if ($h.EndsWith('/')) {
      if ($item.depth -lt $MaxDepth) { $queue.Enqueue(@{ path = $child; depth = $item.depth + 1 }) }
      Say ('          <dir>  ' + $h)
    } else {
      $name = Split-Path $child -Leaf
      if ($name -match $interestingRe) {
        $interesting += $child
        Say ('          FILE*  ' + $h) 'Cyan'
      } else {
        Say ('          file   ' + $h) 'DarkGray'
      }
    }
  }
}

if ($dirCount -ge $MaxDirs) { Say ''; Say ("  [stopped at the $MaxDirs directory cap - raise -MaxDirs to go further]") 'DarkYellow' }

# ---------------------------------------------------------------- sample the interesting ones
Say ''
Say ('  === Sampling ' + $interesting.Count + ' candidate config files (max ' + $MaxFileBytes + ' bytes each) ===') 'Cyan'

$dumpDir = Join-Path $repo ('captures\fileserver-' + $stamp)
$grabbed = 0
# Enforce the byte cap WHILE reading. Invoke-WebRequest buffers the whole response in
# memory before you can check its size, so a runaway or endless file eats RAM until killed.
function Get-Capped($url, $cap) {
  $req = [System.Net.HttpWebRequest]::Create($url)
  $req.Timeout = $TimeoutSec * 1000
  $req.ReadWriteTimeout = $TimeoutSec * 1000
  $resp = $null; $stream = $null
  try {
    $resp = $req.GetResponse()
    $declared = -1
    try { $declared = [int64]$resp.ContentLength } catch {}
    if ($declared -gt $cap) { return @{ tooBig = $true; declared = $declared; bytes = $null } }
    $stream = $resp.GetResponseStream()
    $ms  = New-Object System.IO.MemoryStream
    $buf = New-Object byte[] 32768
    $total = 0
    while ($true) {
      $n = $stream.Read($buf, 0, $buf.Length)
      if ($n -le 0) { break }
      $total += $n
      if ($total -gt $cap) { return @{ tooBig = $true; declared = $total; bytes = $null } }
      $ms.Write($buf, 0, $n)
    }
    return @{ tooBig = $false; declared = $total; bytes = $ms.ToArray() }
  } finally {
    if ($stream) { $stream.Dispose() }
    if ($resp)   { $resp.Close() }
  }
}

foreach ($f in ($interesting | Select-Object -First 40)) {
  try {
    $res = Get-Capped ($base + $f) $MaxFileBytes
    if ($res.tooBig) {
      Say ('  --- ' + $f + '   (' + $res.declared + '+ bytes - over cap, aborted)') 'DarkYellow'
      continue
    }
    $bytes = $res.bytes
    if (-not $bytes) { continue }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    Say ''
    Say ('  --- ' + $f + '   (' + $bytes.Length + ' bytes)') 'Yellow'
    $show = $text
    if ($show.Length -gt 2000) { $show = $show.Substring(0, 2000) + ' ...[truncated in log, full copy saved]' }
    foreach ($l in ($show -split "`r?`n")) { Say ('      ' + $l) 'Green' }

    if (-not (Test-Path $dumpDir)) { New-Item -ItemType Directory -Force -Path $dumpDir | Out-Null }
    $safe = ($f.TrimStart('/') -replace '[\\/:*?"<>|]', '_')
    [System.IO.File]::WriteAllBytes((Join-Path $dumpDir $safe), $bytes)
    $grabbed++
  } catch {
    Say ('  --- ' + $f + '   FAILED: ' + $_.Exception.Message) 'DarkYellow'
  }
}

Say ''
Say ('  Saved ' + $grabbed + ' file(s) to ' + $dumpDir)

# ---------------------------------------------------------------- save transcript
$fileName = "stage2b-fileserver-$($hostName.ToLower())-$stamp.txt"
$written = @()
foreach ($d in @((Join-Path $repo 'captures'), $(if ($SharePath) { Join-Path $SharePath 'captures' } else { $null }))) {
  if (-not $d) { continue }
  try {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null }
    Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop
    $written += (Join-Path $d $fileName)
  } catch { Write-Host ('  could not write to ' + $d) -ForegroundColor DarkYellow }
}
# mirror the grabbed files to the share too
if ($SharePath -and (Test-Path $dumpDir)) {
  try {
    $sd = Join-Path $SharePath ('captures\fileserver-' + $stamp)
    New-Item -ItemType Directory -Force -Path $sd -ErrorAction Stop | Out-Null
    Copy-Item (Join-Path $dumpDir '*') $sd -Force -ErrorAction SilentlyContinue
    Write-Host ('  Mirrored grabbed files to ' + $sd) -ForegroundColor Green
  } catch {}
}

$written = @($written | Select-Object -Unique)
Write-Host ''
Write-Host '  ------------------------------------------------------------------'
if ($written.Count -eq 0) { Write-Host '  NOTHING SAVED - copy the text above by hand' -ForegroundColor Red }
foreach ($w in $written) { Write-Host ('  Saved : ' + $w) -ForegroundColor Green }
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Read-Host '  Press Enter to close'
