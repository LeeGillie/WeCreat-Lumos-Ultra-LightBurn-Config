# stage2-rest-probe.ps1
# Stage 2: probe the controller's HTTP API over the USB RNDIS network link.
#
# READ-ONLY endpoints only. This script will NEVER call POST /test/cmd/mcu, which
# executes G-code immediately and BYPASSES THE LID INTERLOCK. See SAFETY.md.
#
# One endpoint does cause motion: /device/camera/measure_distance moves the head and
# runs an autofocus probe. It is skipped unless you pass -AllowAutofocus.
#
# Usage:
#   .\tools\stage2-rest-probe.ps1                      # auto-detect the RNDIS subnet
#   .\tools\stage2-rest-probe.ps1 -Target 192.168.42.1
#   .\tools\stage2-rest-probe.ps1 -AllowAutofocus      # adds the head-moving probe

param(
  [string] $Target,
  [switch] $AllowAutofocus,
  [int]    $TimeoutSec = 5,
  [string] $SharePath       # also write the capture here (the share this was launched from)
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path $PSScriptRoot -Parent
$hostName = $env:COMPUTERNAME
if (-not $hostName) { try { $hostName = (Get-CimInstance Win32_ComputerSystem).Name } catch { $hostName = 'unknown' } }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = New-Object System.Text.StringBuilder
function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; [void]$log.AppendLine($t) }

Say ''
Say '  Stage 2 - controller HTTP API probe (READ-ONLY)' 'Cyan'
Say ("  host: $hostName    " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Say ''

# ---------------------------------------------------------------- find the controller
if (-not $Target) {
  Say '  Locating the RNDIS link...' 'Yellow'
  $ifs = Get-NetAdapter -ErrorAction SilentlyContinue |
         Where-Object { $_.InterfaceDescription -match 'RNDIS|USB Ethernet|Remote NDIS' -and $_.Status -eq 'Up' }
  foreach ($i in $ifs) {
    $ip = Get-NetIPAddress -InterfaceIndex $i.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -notmatch '^169\.254\.' }
    foreach ($a in $ip) {
      Say ('    ' + $i.Name + '  ' + $i.InterfaceDescription + '  ' + $a.IPAddress + '/' + $a.PrefixLength)
      # the controller is almost certainly .1 on that subnet
      $parts = $a.IPAddress -split '\.'
      $Target = ($parts[0..2] -join '.') + '.1'
    }
  }
  if (-not $Target) { Say '  No RNDIS interface with a routable address. Is the laser connected and powered?' 'Red'; return }
  Say ("  guessing controller at: $Target") 'Yellow'
}
Say ''

# ---------------------------------------------------------------- port scan
Say ('  --- ports on ' + $Target + ' ---') 'Yellow'
function Test-Port($h, $p, $ms = 900) {
  $c = New-Object System.Net.Sockets.TcpClient
  try {
    $iar = $c.BeginConnect($h, $p, $null, $null)
    $ok = $iar.AsyncWaitHandle.WaitOne($ms, $false) -and $c.Connected
    $c.Close(); return $ok
  } catch { return $false }
}
$openPorts = @()
foreach ($p in @(22, 80, 8080, 8082, 8888)) {
  $o = Test-Port $Target $p
  if ($o) { $openPorts += $p }
  $what = switch ($p) { 22 {'SSH'} 80 {'HTTP'} 8080 {'REST API'} 8082 {'file listing'} 8888 {'?'} }
  Say ('    {0,-6} {1,-14} {2}' -f $p, $what, $(if ($o) { 'OPEN' } else { 'closed' })) $(if ($o) { 'Green' } else { 'DarkGray' })
}
Say ''

if ($openPorts -notcontains 8080) {
  Say '  Port 8080 is not open. The Vision-generation REST API may have moved or gone.' 'Red'
  Say '  Try: -Target with a different address, or capture MakeIt traffic in Wireshark' 'Red'
  Say '  on the RNDIS interface to find the real API.' 'Red'
}

# ---------------------------------------------------------------- endpoints
function Hit($method, $path, $desc) {
  $url = "http://${Target}:8080$path"
  Say ''
  Say ('  --- ' + $method + ' ' + $path) 'Yellow'
  Say ('      ' + $desc) 'DarkGray'
  try {
    $r = Invoke-WebRequest -Uri $url -Method $method -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
    Say ('      HTTP ' + $r.StatusCode + '   ' + $r.Headers['Content-Type'] + '   ' + $r.RawContentLength + ' bytes') 'Green'
    $ct = [string]$r.Headers['Content-Type']
    if ($ct -match 'image') {
      $out = Join-Path $repo ('captures\camera-' + $stamp + '.jpg')
      [System.IO.File]::WriteAllBytes($out, $r.Content)
      Say ('      image saved to ' + $out) 'Green'
      Say '      >> open it: how many cameras? one frame or a composite? orientation?' 'Cyan'
    } else {
      $body = $r.Content
      if ($body -is [byte[]]) { $body = [System.Text.Encoding]::UTF8.GetString($body) }
      $s = [string]$body
      if ($s.Length -gt 1600) { $s = $s.Substring(0, 1600) + ' ...[truncated]' }
      foreach ($l in ($s -split "`r?`n")) { Say ('      ' + $l) 'Green' }
    }
  } catch {
    Say ('      FAILED: ' + $_.Exception.Message) 'DarkYellow'
  }
}

Hit 'GET'  '/camera/take_photo'        'Single still from the overhead camera'
Hit 'GET'  '/device/camera/download'   'Camera calibration data'
Hit 'POST' '/process/status'           'Machine status'

if ($AllowAutofocus) {
  Say ''
  Say '  !! The next call MOVES THE HEAD and runs an autofocus probe.' 'Red'
  Say '     Make sure the bed is clear and something is under the target point.' 'Red'
  Start-Sleep -Seconds 5
  Hit 'GET' '/device/camera/measure_distance?x=105&y=105' 'Autofocus probe at bed centre - CAUSES MOTION'
} else {
  Say ''
  Say '  (skipped /device/camera/measure_distance - it moves the head.' 'DarkGray'
  Say '   re-run with -AllowAutofocus if you want it, bed clear.)' 'DarkGray'
}

Say ''
Say '  NOT CALLED, DELIBERATELY: POST /test/cmd/mcu' 'Red'
Say '  That endpoint executes G-code and bypasses the lid interlock. See SAFETY.md.' 'Red'

# ---------------------------------------------------------------- save
$fileName = "stage2-rest-$($hostName.ToLower())-$stamp.txt"
$written = @()
try {
  $d = Join-Path $repo 'captures'
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8
  $written += (Join-Path $d $fileName)
} catch {}
$shareTargets = @()
if ($SharePath) { $shareTargets += $SharePath }
try {
  $origin = (& git -C $repo remote get-url origin 2>$null)
  if ($origin -and $origin.StartsWith('\\')) { $shareTargets += $origin }
} catch {}

foreach ($s in ($shareTargets | Select-Object -Unique)) {
  try {
    $d = Join-Path $s 'captures'
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null }
    Set-Content -Path (Join-Path $d $fileName) -Value $log.ToString() -Encoding UTF8 -ErrorAction Stop
    $written += (Join-Path $d $fileName)
    # the camera still, if we got one
    $img = Join-Path $repo ('captures\camera-' + $stamp + '.jpg')
    if (Test-Path $img) { Copy-Item $img (Join-Path $d ('camera-' + $stamp + '.jpg')) -Force -ErrorAction SilentlyContinue }
  } catch {
    Write-Host ('  could not write to ' + $s + ' : ' + $_.Exception.Message) -ForegroundColor DarkYellow
  }
}

Write-Host ''
Write-Host '  ------------------------------------------------------------------'
if ($written.Count -eq 0) { Write-Host '  NOTHING SAVED - copy the text above by hand' -ForegroundColor Red }
foreach ($w in $written) { Write-Host ('  Saved : ' + $w) -ForegroundColor Green }
Write-Host '  ------------------------------------------------------------------'
Write-Host ''
Read-Host '  Press Enter to close'
