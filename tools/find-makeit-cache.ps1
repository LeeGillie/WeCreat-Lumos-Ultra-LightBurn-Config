<#
.SYNOPSIS
    Find where MakeIt stages job G-code on the PC before uploading it to the machine.

.DESCRIPTION
    Read-only. Touches nothing, sends nothing to the laser.

    MakeIt is an Electron application, so it almost certainly writes the generated
    toolpath to a working directory before POSTing it to the controller. This script
    finds that directory the easy way: run a job in MakeIt, then run this immediately
    afterwards and look at everything that changed.

    Run this on BENCHY (the machine MakeIt is installed on), NOT on cortex.

.PARAMETER Minutes
    How far back to look. Default 15. Use a small value right after running a job.

.PARAMETER Deep
    Also sweep the whole user profile and C:\ProgramData. Slower, but catches
    installers that put their working directory somewhere unusual.

.EXAMPLE
    .\find-makeit-cache.ps1
    .\find-makeit-cache.ps1 -Minutes 5
    .\find-makeit-cache.ps1 -Deep
#>

[CmdletBinding()]
param(
    [int] $Minutes = 15,
    [switch] $Deep
)

$ErrorActionPreference = 'SilentlyContinue'
$cutoff = (Get-Date).AddMinutes(-$Minutes)

Write-Host ''
Write-Host '  MakeIt staging-directory hunt (READ-ONLY)' -ForegroundColor Cyan
Write-Host ("  host: {0}   looking back {1} minute(s)   cutoff {2}" -f $env:COMPUTERNAME, $Minutes, $cutoff.ToString('HH:mm:ss'))
Write-Host ''

# ---------------------------------------------------------------- search roots

$roots = New-Object System.Collections.Generic.List[string]
foreach ($r in @($env:APPDATA, $env:LOCALAPPDATA, $env:TEMP, "$env:LOCALAPPDATA\Temp")) {
    if ($r -and (Test-Path $r)) { $roots.Add($r) }
}
if ($Deep) {
    foreach ($r in @($env:USERPROFILE, 'C:\ProgramData')) {
        if ($r -and (Test-Path $r)) { $roots.Add($r) }
    }
}
$roots = $roots | Select-Object -Unique

Write-Host '  --- roots ---'
foreach ($r in $roots) { Write-Host ("        {0}" -f $r) }
Write-Host ''

# --------------------------------------------- 1. directories that name the app

Write-Host '  === 1. Folders whose name mentions MakeIt or WeCreat ===' -ForegroundColor Yellow
$appDirs = @()
foreach ($r in $roots) {
    $appDirs += Get-ChildItem -LiteralPath $r -Recurse -Directory -Depth 3 |
                Where-Object { $_.Name -match '(?i)makeit|wecreat|mbtc' }
}
$appDirs = $appDirs | Select-Object -ExpandProperty FullName -Unique
if ($appDirs) {
    foreach ($d in $appDirs) { Write-Host ("        {0}" -f $d) -ForegroundColor Green }
} else {
    Write-Host '        (none found - the app may use a generic Electron folder name)'
}
Write-Host ''

# ------------------------------------------------ 2. recently written toolpaths

Write-Host '  === 2. Toolpath-looking files written recently ===' -ForegroundColor Yellow
$hits = @()
foreach ($r in $roots) {
    $hits += Get-ChildItem -LiteralPath $r -Recurse -File |
             Where-Object {
                 $_.LastWriteTime -gt $cutoff -and
                 $_.Extension -match '(?i)^\.(gcode|gc|nc|ngc|tap|cnc|txt|json|bin|dat)$'
             }
}
$hits = $hits | Sort-Object LastWriteTime -Descending | Select-Object -Unique

if (-not $hits) {
    Write-Host '        (nothing - try a larger -Minutes, or -Deep)'
} else {
    foreach ($f in $hits) {
        Write-Host ('        {0,-9} {1,10:N0} b   {2}' -f `
            $f.LastWriteTime.ToString('HH:mm:ss'), $f.Length, $f.FullName)
    }
}
Write-Host ''

# ------------------------------------- 3. which of those are actually WeCreat G-code

Write-Host '  === 3. Files that really are WeCreat G-code ===' -ForegroundColor Yellow
Write-Host '  (looking for the ";wecreat" header or M107/M18 in the first few lines)'
Write-Host ''

$confirmed = @()
foreach ($f in $hits) {
    if ($f.Length -gt 40MB) { continue }
    $head = Get-Content -LiteralPath $f.FullName -TotalCount 12
    if (-not $head) { continue }
    $joined = ($head -join "`n")
    if ($joined -match '(?i);\s*wecreat|M107X-?\d|canvas border|^M18S[01]') {
        $confirmed += $f
        Write-Host ('  >>> {0}' -f $f.FullName) -ForegroundColor Green
        Write-Host ('      {0:N0} bytes, written {1}' -f $f.Length, $f.LastWriteTime)
        foreach ($line in ($head | Select-Object -First 10)) {
            Write-Host ('        | {0}' -f $line)
        }
        Write-Host ''
    }
}

if (-not $confirmed) {
    Write-Host '        (no confirmed WeCreat G-code among the recent files)'
    Write-Host '        MakeIt may build the toolpath in memory and POST it without'
    Write-Host '        ever touching disk. That would still be worth recording.'
    Write-Host ''
}

# ------------------------------------------------------------------- 4. summary

Write-Host '  === Summary ===' -ForegroundColor Cyan
Write-Host ('        app-named folders : {0}' -f $appDirs.Count)
Write-Host ('        recent candidates : {0}' -f $hits.Count)
Write-Host ('        confirmed G-code  : {0}' -f $confirmed.Count)
Write-Host ''
if ($confirmed) {
    Write-Host '  Copy one out and diff it against the same artwork saved from LightBurn.'
    Write-Host '  That is the single most useful comparison available to this project:'
    Write-Host '  one machine, one drawing, two toolpath generators.'
    Write-Host ''
}
