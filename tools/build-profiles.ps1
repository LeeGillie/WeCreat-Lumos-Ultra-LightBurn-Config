# build-profiles.ps1
# Generates the draft LightBurn device profiles from tools/profile-spec.json.
#
# DEVICE CLASS: "Custom GCode" with GCodeFlavor "wecreat".
#
# LightBurn 2.1.04 detects WeCreat machines from their serial banner and warns if you are not
# using a Custom GCode device with the WeCreat flavor. WeCreat's own WeCreat-Lumos-v1.5.lbdev
# declares "Name":"GRBL" - it dates from August 2025 and predates the flavor, so the vendor's
# published profile now triggers the same warning.
#
# The key names and the exact Settings key set below were read from a Custom GCode / WeCreat
# device built in LightBurn 2.1.04's own wizard, not guessed from documentation.
# See captures/stage3-lightburn-connect-benchy.md.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-profiles.ps1

$root = Split-Path $PSScriptRoot -Parent
$spec = Get-Content (Join-Path $PSScriptRoot 'profile-spec.json') -Raw | ConvertFrom-Json
$out  = Join-Path $root 'profiles\draft'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$sh = $spec.shared

function New-Settings {
  # Exactly the keys LightBurn 2.1.04 writes for a Custom GCode device - no more, no less.
  # Adding GRBL-only keys here (CutOrigin, rotary*, StartGCode, Sim_*) does nothing: the
  # Custom GCode driver does not read them.
  [ordered]@{
    AllowComms           = $true
    BaudRate             = $sh.baudRate
    ControlUnits         = 1
    DwellIsMilliseconds  = $false
    EnableDTR            = $false
    GCodeFlavor          = $sh.gcodeFlavor      # "wecreat"
    IsTextBased          = $true
    NetworkPort          = 23
    S_Scale              = $sh.sScale
    TargetBufferSize     = 127
    ToolStateIsAutomatic = $true
    TransferMode         = 0
    Units                = 1
    UseHardwareFlow      = $false
    UserFinishX          = 0
    UserFinishY          = 0
    VariableLaserPower   = $true
  }
}

$made = 0
foreach ($p in $spec.profiles) {

  $header = @(
    ('=== ' + $p.displayName + ' ==='),
    ('Source: ' + $p.source + '    Lens: ' + $p.lens),
    '',
    'DRAFT - NOT FULLY VERIFIED ON HARDWARE.',
    'Confirmed: 210x210 field, GRBL-over-serial at 1000000 baud, WeCreat GCode flavor.',
    'Unverified: origin corner and mirroring - check by framing before running a job.',
    ''
  )
  $checklist = (($header + $p.checklist) -join "`n")

  $device = [ordered]@{
    Checklist                   = $checklist
    CustomAlarmCodes            = @{}
    CustomErrorCodes            = @{}
    DefaultCutList              = @()
    DefaultToolCutList          = @()
    DisplayName                 = $p.displayName
    EnableLaser2Offset          = $false
    EnableProcessOffset         = $false
    GUID                        = $p.guid
    Height                      = $p.height
    HomeOnStartup               = $false      # homing behaviour unverified; Pn:Z reads asserted at rest
    Info                        = ''
    JogContinuous               = $false
    Laser2OffsetX               = 0
    Laser2OffsetY               = 0
    LastCamera                  = ''
    LastCameraName              = ''
    LastDevLibraryPath          = ''
    Macros                      = @()         # 2.x format: array of {Label, Content}, not Macro0_*
    MirrorX                     = $sh.mirrorX
    MirrorY                     = $sh.mirrorY
    MoveJogDistance             = 10
    MoveJogFromOrigin           = $true
    MoveJogSpeed                = 13.333333015441895
    MoveJogZDistance            = 10
    MoveJogZSpeed               = 4.166600227355957
    Name                        = $sh.driver          # "Custom GCode"
    PositionTimerEnable         = $true
    ProcessOffsetX              = 0
    ProcessOffsetY              = 0
    ProfilePath                 = $sh.driver
    ReverseIntervalCompensation = $false
    Settings                    = (New-Settings)
    ToolPower                   = 0
    Type                        = $sh.connection
    Width                       = $p.width
  }

  $doc  = [ordered]@{ DeviceList = @($device) }
  $json = $doc | ConvertTo-Json -Depth 12
  # LightBurn writes 4-space indent; ConvertTo-Json uses 2. Normalise for clean diffs.
  $json = ($json -split "`r?`n" | ForEach-Object {
    if ($_ -match '^(\s+)') { ($Matches[1] * 2) + $_.TrimStart() } else { $_ }
  }) -join "`n"

  # LF endings and UTF-8 without BOM, to match .gitattributes and keep diffs stable.
  $path = Join-Path $out $p.file
  [System.IO.File]::WriteAllText($path, $json + "`n", (New-Object System.Text.UTF8Encoding $false))
  Write-Output ('  wrote  {0,-46}  {1} x {2} mm' -f $p.file, $p.width, $p.height)
  $made++
}

Write-Output ''
Write-Output ("Generated $made draft profile(s) in profiles\draft")
Write-Output ('Device class: ' + $sh.driver + '   flavor: ' + $sh.gcodeFlavor + '   baud: ' + $sh.baudRate)
Write-Output 'Review with:   .\tools\summarize-lbdev.ps1'
Write-Output 'Validate with: .\tools\validate-lbdev.ps1'
