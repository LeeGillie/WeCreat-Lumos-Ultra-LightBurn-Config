# probe-workstation.ps1
# Read-only survey of this PC for WeCreat MakeIt and LightBurn installs, serial ports,
# and RNDIS gadgets. Sends NOTHING to the laser and fires no beam. Safe to run any time.
#
# Usage:   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\probe-workstation.ps1
# Capture: ... -File .\tools\probe-workstation.ps1 > .\captures\workstation-<yourname>.txt

Write-Output ('WeCreat Lumos Ultra / LightBurn workstation probe  -  ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$hostName = $env:COMPUTERNAME
if (-not $hostName) { try { $hostName = (Get-CimInstance Win32_ComputerSystem).Name } catch { $hostName = 'unknown' } }
Write-Output ('Host: ' + $hostName + '   User: ' + $env:USERNAME + '   OS: ' + (Get-CimInstance Win32_OperatingSystem).Caption)
Write-Output ''

Write-Output '=== 1. Install locations ==='
foreach ($root in @('C:\Program Files','C:\Program Files (x86)','D:\Program Files','D:\Program Files (x86)', (Join-Path $env:LOCALAPPDATA 'Programs'))) {
  if (Test-Path $root) {
    Get-ChildItem $root -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match 'creat|make ?it|lightburn' } |
      ForEach-Object { Write-Output ('  ' + $_.FullName) }
  }
}

Write-Output ''
Write-Output '=== 2. Uninstall registry entries ==='
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty $keys -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match 'creat|make ?it|lightburn' } |
  ForEach-Object { Write-Output ('  {0} | v{1} | {2}' -f $_.DisplayName, $_.DisplayVersion, $_.InstallLocation) }

Write-Output ''
Write-Output '=== 3. Config / data folders ==='
foreach ($p in @(
  (Join-Path $env:APPDATA     'LightBurn'),
  (Join-Path $env:LOCALAPPDATA 'LightBurn'),
  (Join-Path $env:APPDATA     'MakeIt'),
  (Join-Path $env:APPDATA     'WeCreat'),
  (Join-Path $env:LOCALAPPDATA 'MakeIt'),
  (Join-Path $env:LOCALAPPDATA 'WeCreat'),
  (Join-Path $env:USERPROFILE '.LightBurn')
)) {
  if (Test-Path $p) { Write-Output ('  FOUND  ' + $p) } else { Write-Output ('  -      ' + $p) }
}

Write-Output ''
Write-Output '=== 4. Serial ports present right now ==='
Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '\(COM\d+\)' } |
  ForEach-Object { Write-Output ('  {0}' -f $_.Name); Write-Output ('      HWID: {0}' -f $_.DeviceID) }

Write-Output ''
Write-Output '=== 5. RNDIS / USB-Ethernet gadgets (the WeCreat controller shows up here) ==='
Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match 'RNDIS|USB Ethernet|Remote NDIS' } |
  ForEach-Object { Write-Output ('  {0}' -f $_.Name); Write-Output ('      HWID: {0}' -f $_.DeviceID) }

Write-Output ''
Write-Output '=== 6. All USB devices with a VID/PID (grep this for your laser) ==='
Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
  Where-Object { $_.DeviceID -match 'VID_[0-9A-F]{4}&PID_[0-9A-F]{4}' } |
  Sort-Object Name -Unique |
  ForEach-Object {
    if ($_.DeviceID -match '(VID_[0-9A-F]{4}&PID_[0-9A-F]{4})') {
      Write-Output ('  {0,-22}  {1}' -f $Matches[1], $_.Name)
    }
  }

Write-Output ''
Write-Output '=== 7. Network adapters + addresses (find the RNDIS subnet) ==='
Get-NetAdapter -ErrorAction SilentlyContinue |
  Select-Object Name, InterfaceDescription, Status, LinkSpeed |
  ForEach-Object { Write-Output ('  {0,-24} {1,-40} {2} {3}' -f $_.Name, $_.InterfaceDescription, $_.Status, $_.LinkSpeed) }
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.IPAddress -notmatch '^127\.' } |
  ForEach-Object { Write-Output ('  {0,-24} {1}/{2}' -f $_.InterfaceAlias, $_.IPAddress, $_.PrefixLength) }

Write-Output ''
Write-Output '=== 8. LightBurn version ==='
$lbFound = $false
Get-ItemProperty $keys -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match 'LightBurn' } |
  ForEach-Object { Write-Output ('  {0}' -f $_.DisplayName); $script:lbFound = $true; $lbFound = $true }
foreach ($lb in @('C:\Program Files\LightBurn\LightBurn.exe','D:\Program Files\LightBurn\LightBurn.exe')) {
  if (Test-Path $lb) {
    $vi = (Get-Item $lb).VersionInfo
    Write-Output ('  {0}  file v{1}' -f $lb, $vi.FileVersion)
    $lbFound = $true
  }
}
if (-not $lbFound) { Write-Output '  LightBurn not found' }
Write-Output '  NOTE: use LightBurn 2.1.02 or newer. Earlier builds desynchronise on WeCreat firmware.'

Write-Output ''
Write-Output '=== 9. Test-machine prerequisites ==='
foreach ($t in @(
  @{ n = 'git';    c = 'git';    a = '--version' },
  @{ n = 'node';   c = 'node';   a = '--version' },
  @{ n = 'python'; c = 'python'; a = '--version' },
  @{ n = 'gh';     c = 'gh';     a = '--version' }
)) {
  $cmd = Get-Command $t.c -ErrorAction SilentlyContinue
  if ($cmd) {
    $v = (& $t.c $t.a 2>&1 | Select-Object -First 1)
    Write-Output ('  {0,-8} {1}' -f $t.n, $v)
  } else {
    Write-Output ('  {0,-8} NOT INSTALLED' -f $t.n)
  }
}
Write-Output '  (git is required to clone the repo. node is optional - only for the MakeIt inspection tools.'
Write-Output '   python is optional - only if you prefer miniterm for the Stage 1 serial probe.)'

Write-Output ''
Write-Output '=== 10. Readiness summary ==='
$serial = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\(COM\d+\)' -and $_.Name -notmatch 'Bluetooth' })
$rndis  = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'RNDIS|USB Ethernet|Remote NDIS' })
Write-Output ('  non-Bluetooth COM ports : ' + $serial.Count)
Write-Output ('  RNDIS gadgets           : ' + $rndis.Count)
if ($serial.Count -eq 0 -and $rndis.Count -eq 0) {
  Write-Output '  >> No laser detected. Is the Ultra powered on and the USB cable connected?'
  Write-Output '  >> Also close WeCreat MakeIt entirely - it holds the serial port.'
} else {
  Write-Output '  >> Something is attached. Record the hardware IDs from sections 4-6 above.'
}

Write-Output ''
Write-Output '=== END ==='
