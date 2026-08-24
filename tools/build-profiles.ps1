# build-profiles.ps1
# Generates the draft LightBurn device profiles from tools/profile-spec.json.
#
# Every value written here is authored by this project. The vendor's own .lbdev files were used
# as a structural reference for which keys LightBurn expects; none of their content is copied.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-profiles.ps1

$root = Split-Path $PSScriptRoot -Parent
$spec = Get-Content (Join-Path $PSScriptRoot 'profile-spec.json') -Raw | ConvertFrom-Json
$out  = Join-Path $root 'profiles\draft'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$sh = $spec.shared

function New-Settings($p) {
  [ordered]@{
    AirAssistM7               = $false
    AlignH                    = 0
    AlignV                    = 0
    BaudRate                  = $sh.baudRate
    Checklist                 = $true          # show the start-of-job checklist
    ClickSelTolerance         = 3
    CommPort                  = $sh.commPort
    ContinuousFrame           = $false
    CutOrigin                 = $sh.cutOrigin
    DockState_ArtBrowser      = $false
    DockState_Camera          = $false
    DockState_Console         = $true
    DockState_CutLibrary      = $true
    DockState_LaserFiles      = $false
    DockState_Move            = $true
    DockState_ShapeProperties = $false
    DockState_VariableText    = $false
    EnableBoundsCheck         = $false
    EnableDTR                 = $false
    EnableGrblJCommand        = $false
    EnableU                   = $false
    EnableUserFinish          = $false
    EnableZ                   = $sh.enableZ
    EndGCode                  = $sh.endGCode
    ForceSValueOutput         = $false
    GCodeClustering           = $false
    GridShade                 = 224
    GridSnap                  = 1
    GridSnapEnabled           = $true
    GridSpacing               = 10
    LaserFire_Enable          = $false
    LaserFire_Power           = 0
    LaserFrame_Enable         = $false
    LastExportExt             = 'gc'
    LastMachineFileExtension  = ''
    LastMachineFilePath       = ''
    Macro0_Content            = ''
    Macro0_Label              = ''
    Macro1_Content            = ''
    Macro1_Label              = ''
    Macro2_Content            = ''
    Macro2_Label              = ''
    Macro3_Content            = ''
    Macro3_Label              = ''
    Macro4_Content            = ''
    Macro4_Label              = ''
    Macro5_Content            = ''
    Macro5_Label              = ''
    NegativeWorkspace         = $false
    NegativeZ                 = $false
    OMTechPolar               = $false
    ObjSnap                   = 10
    ObjSnapEnabled            = $true
    OptimizeZ                 = $false
    RelativeZOnly             = $sh.relativeZOnly
    S_Scale                   = $sh.sScale
    Sim_CornerTolerance       = 0.01
    Sim_FastWhiteScan         = $false
    Sim_FastWhiteScanSpeed    = 999
    Sim_GlobalFactor          = 1
    Sim_MaxAccelX             = $sh.simMaxAccelX
    Sim_MaxAccelY             = $sh.simMaxAccelY
    Sim_MaxSpeedX             = $sh.simMaxSpeedX
    Sim_MaxSpeedY             = $sh.simMaxSpeedY
    Sim_MinCornerSpeed        = 1
    Sim_RapidSpeed            = 400
    Sim_ScanAccelX            = $sh.simMaxAccelX
    Sim_ScanAccelY            = $sh.simMaxAccelY
    Sim_SpeedFactor           = 1
    SkipWhiteFlag             = $false
    SkipWhiteSpeed            = 999
    StartGCode                = $sh.startGCode
    SwapXYOutput              = $false
    TabPulseWidth             = 0.1
    TransferMode              = 0
    Units                     = 0
    UseG0ForOverscan          = $false
    UserFinishX               = 0
    UserFinishY               = 0
    mirrorRotaryOutput        = $false
    overwriteFileByDefault    = $false
    rotaryAxis                = $sh.rotaryAxis
    rotaryDiameter            = $sh.rotaryDiameter
    rotaryIsChuck             = $sh.rotaryIsChuck
    rotaryMode                = $sh.rotaryMode
    rotarySteps               = $sh.rotarySteps
  }
}

$made = 0
foreach ($p in $spec.profiles) {

  $header = @(
    ('=== ' + $p.displayName + ' ==='),
    ('Source: ' + $p.source + '    Lens: ' + $p.lens),
    '',
    'DRAFT - NOT VERIFIED ON HARDWARE.',
    'Start/end G-code and macros are intentionally empty; see docs/04-mcode-dictionary.md.',
    ''
  )
  $checklist = (($header + $p.checklist) -join "`n")

  $device = [ordered]@{
    Checklist                  = $checklist
    DefaultCutList             = @()
    DefaultToolCutList         = @()
    DisplayName                = $p.displayName
    EnableLaser2Offset         = $false
    EnableProcessOffset        = $false
    GUID                       = $p.guid
    Height                     = $p.height
    HomeOnStartup              = $sh.homeOnStartup
    Info                       = ''
    Laser2OffsetX              = 0
    Laser2OffsetY              = 0
    LastCamera                 = ''
    LastDevLibraryPath         = ''
    MirrorX                    = $sh.mirrorX
    MirrorY                    = $sh.mirrorY
    Name                       = $sh.driver
    ProcessOffsetX             = 0
    ProcessOffsetY             = 0
    ReverseIntervalCompensation = $false
    Settings                   = (New-Settings $p)
    Type                       = $sh.connection
    Width                      = $p.width
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
Write-Output 'Review with:  .\tools\summarize-lbdev.ps1'
Write-Output 'Validate with: .\tools\validate-lbdev.ps1'
