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
  param([string] $StartGCode = '')

  # A minimal Settings block. LightBurn fills the remaining ~80 keys with its own defaults on
  # import - verified against a live prefs.ini from a working machine on 2026-08-25.
  #
  # CORRECTION (2026-08-25): an earlier version of this comment claimed the Custom GCode driver
  # ignores StartGCode / EndGCode. It does not. Both keys are present and live on a working
  # Custom GCode device, and StartGCode is REQUIRED here - see below.
  [ordered]@{
    AllowComms           = $true
    BaudRate             = $sh.baudRate
    ControlUnits         = 1
    DwellIsMilliseconds  = $false
    EnableDTR            = $false
    EndGCode             = $sh.endGCode
    GCodeFlavor          = $sh.gcodeFlavor      # "wecreat"
    HasAir               = $false               # no air assist; M8 is rejected by the firmware
    IsTextBased          = $true
    NetworkPort          = 23
    S_Scale              = $sh.sScale

    # SOURCE SELECT - REQUIRED, NOT OPTIONAL.
    # M18S0 = MOPA fiber, M18S1 = UV. Without it the machine accepts the job, streams it, and
    # marks nothing at any power. The \x18 soft reset LightBurn sends on every Stop clears it,
    # so it has to be re-asserted per job. CONFIRMED-hardware 2026-08-25.
    StartGCode           = $StartGCode

    TargetBufferSize     = 128
    ToolStateIsAutomatic = $true
    TransferMode         = 0
    Units                = 1
    UseHardwareFlow      = $false
    UserFinishX          = 0
    UserFinishY          = 0
    VariableLaserPower   = $true

    # Echo every streamed line in the Console. This machine has no usable status telemetry
    # beyond position, so the stream echo is the only window into what LightBurn actually
    # sent. Diagnosing anything without it means inferring from whether the metal changed.
    VerboseOutput        = $true
  }
}

$made = 0
foreach ($p in $spec.profiles) {

  $header = @(
    ('=== ' + $p.displayName + ' ==='),
    ('Source: ' + $p.source + '    Lens: ' + $p.lens),
    '',
    'Confirmed on hardware: 210x210 field, 1000000 baud, wecreat GCode flavor,',
    'top-left origin, no field distortion at 200mm, and source select via start G-code.',
    'AIR ASSIST OFF - M8 is rejected by the firmware.',
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
    Settings                    = (New-Settings -StartGCode ([string]$p.startGCode))
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
