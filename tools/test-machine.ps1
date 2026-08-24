# test-machine.ps1
# Entry point for the machine that has the Lumos Ultra attached.
#
# Syncs a local copy of the repository, then offers the bring-up stages as a menu,
# so a machine reached over a remote-desktop tool with no shared clipboard needs
# only one short path typed to do everything.
#
# Stages 0-2 are READ-ONLY: no beam, no motion (one opt-in exception in Stage 2,
# clearly flagged). See SAFETY.md.

$ErrorActionPreference = 'Continue'

$source = Split-Path $PSScriptRoot -Parent      # where this was launched from
$who = $env:COMPUTERNAME
if (-not $who) { try { $who = (Get-CimInstance Win32_ComputerSystem).Name } catch {} }
if (-not $who) { $who = 'unknown-host' }
$who = $who.ToLower()

# A breadcrumb on the share, so the authoring machine can see how far a run got even
# when the test machine cannot easily copy text off itself.
function Trace($what) {
  try {
    $d = Join-Path $source 'captures'
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null }
    $line = ('{0}  {1}  {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $who, $what)
    Add-Content -Path (Join-Path $d ('_runlog-' + $who + '.txt')) -Value $line -ErrorAction Stop
  } catch { }
}

function Banner {
  Clear-Host
  Write-Host ''
  Write-Host '  ==================================================================' -ForegroundColor DarkCyan
  Write-Host '   WeCreat Lumos Ultra  -  LightBurn configuration project' -ForegroundColor Cyan
  Write-Host '   Test machine console' -ForegroundColor Cyan
  Write-Host '  ==================================================================' -ForegroundColor DarkCyan
  Write-Host ("   machine : $who")
  Write-Host ("   source  : $source")
  Write-Host ("   local   : $script:local")
  Write-Host ''
}

# ---------------------------------------------------------------- local copy
$candidates = @('D:\Dev', 'D:\DevHome', 'C:\Dev', (Join-Path $env:USERPROFILE 'Dev'))
$parent = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $parent) { $parent = Join-Path $env:USERPROFILE 'Dev'; New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$script:local = Join-Path $parent 'WeCreat Lumos Ultra Lightburn Config'

function Sync-Local {
  Write-Host '  Syncing local copy...' -ForegroundColor Yellow
  $sameDir = $script:local.TrimEnd('\').ToLower() -eq $source.TrimEnd('\').ToLower()
  if ($sameDir) { Write-Host '    running from the local repo already - nothing to sync'; return }

  $hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)

  if ($hasGit -and (Test-Path (Join-Path $script:local '.git'))) {
    Push-Location $script:local
    # A clone made from a UNC path can end up without tracking info. Repair it rather
    # than failing, so this is safe to re-run.
    $origin = (& git remote get-url origin 2>$null)
    if (-not $origin) {
      Write-Host '    no origin remote - adding one pointing at the share'
      & git remote add origin $source 2>&1 | Out-Null
    } elseif ($origin.TrimEnd('\') -ne $source.TrimEnd('\')) {
      Write-Host ('    origin was ' + $origin + ' - repointing at the share')
      & git remote set-url origin $source 2>&1 | Out-Null
    }
    & git fetch origin 2>&1 | ForEach-Object { Write-Host ('    ' + $_) }
    $branch = (& git rev-parse --abbrev-ref HEAD 2>$null)
    if (-not $branch) { $branch = 'main' }
    & git branch --set-upstream-to=("origin/" + $branch) $branch 2>&1 | Out-Null
    $dirty = (& git status --porcelain)
    if ($dirty) {
      Write-Host '    local changes present - fetching only, not merging:' -ForegroundColor DarkYellow
      $dirty | ForEach-Object { Write-Host ('      ' + $_) -ForegroundColor DarkYellow }
    } else {
      $merge = (& git merge --ff-only ("origin/" + $branch) 2>&1)
      $merge | ForEach-Object { Write-Host ('    ' + $_) }
      if ($LASTEXITCODE -ne 0) {
        Write-Host '    Could not fast-forward the local copy.' -ForegroundColor DarkYellow
        Write-Host '    This is harmless: the stages run from the share, which is authoritative.' -ForegroundColor DarkYellow
        Write-Host '    To get a clean local clone for committing captures, rename the folder and' -ForegroundColor DarkYellow
        Write-Host '    pick (s) again, or delete it and re-run this launcher.' -ForegroundColor DarkYellow
      }
    }
    Pop-Location
  }
  elseif ($hasGit) {
    Write-Host ('    git clone -> ' + $script:local)
    & git clone $source $script:local 2>&1 | ForEach-Object { Write-Host ('    ' + $_) }
  }
  else {
    Write-Host '    git not found - plain file copy (install git to commit captures)' -ForegroundColor DarkYellow
    New-Item -ItemType Directory -Force -Path $script:local | Out-Null
    & robocopy $source $script:local /E /XD .git reference /NFL /NDL /NJH /NJS /NP | Out-Null
  }

  if (-not (Test-Path $script:local)) {
    Write-Host '    FAILED to create a local copy. Check share access.' -ForegroundColor Red
    $script:local = $source
  }
}

function Run-Stage($scriptName, $extraArgs) {
  # Prefer the copy on the SHARE. It is the authoritative one, and a local clone can be
  # stale or have an unrelated history that will not fast-forward - in which case running
  # the local copy would silently use an older script.
  $p = Join-Path $source ('tools\' + $scriptName)
  if (-not (Test-Path $p)) { $p = Join-Path $script:local ('tools\' + $scriptName) }
  if (-not (Test-Path $p)) { Write-Host ('  not found: ' + $scriptName) -ForegroundColor Red; Read-Host '  Enter'; return }
  Write-Host ''
  # Always tell the stage where the share is, so the capture comes back even if
  # the local clone has no usable git origin.
  $a = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$p,'-SharePath',$source)
  if ($extraArgs) { $a += $extraArgs }
  & powershell @a
}

function Stage0 {
  $probe = Join-Path $source 'tools\probe-workstation.ps1'
  if (-not (Test-Path $probe)) { $probe = Join-Path $script:local 'tools\probe-workstation.ps1' }
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $result = & powershell -NoProfile -ExecutionPolicy Bypass -File $probe 2>&1 | Out-String
  $fileName = "stage0-usb-$who-$stamp.txt"
  $written = @()
  foreach ($dest in @((Join-Path $script:local 'captures'), (Join-Path $source 'captures'))) {
    try {
      if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
      Set-Content -Path (Join-Path $dest $fileName) -Value $result -Encoding UTF8 -ErrorAction Stop
      $written += (Join-Path $dest $fileName)
    } catch {}
  }
  $show = $false
  foreach ($l in ($result -split "`r?`n")) {
    if ($l -match '^=== (4|5|9|10)\.') { $show = $true } elseif ($l -match '^=== ') { $show = $false }
    if ($show) {
      $c = 'Gray'
      if ($l -match '^\s*>>') { $c = 'Green' }
      if ($l -match 'No laser detected') { $c = 'Red' }
      if ($l -match '^=== ') { $c = 'White' }
      Write-Host ('  ' + $l) -ForegroundColor $c
    }
  }
  Write-Host ''
  foreach ($w in $written) { Write-Host ('  Saved : ' + $w) -ForegroundColor Green }
  Write-Host ''
  Read-Host '  Press Enter for the menu'
}

# ---------------------------------------------------------------- menu
Trace 'launcher started'
Banner
Sync-Local
Trace 'sync complete'
Write-Host ''
Read-Host '  Press Enter for the menu'

while ($true) {
  Banner
  Write-Host '   Bring-up stages       (see docs/03-bringup-plan.md)' -ForegroundColor White
  Write-Host ''
  Write-Host '     0   Stage 0  USB enumeration          no beam, no motion'
  Write-Host '     1   Stage 1  serial identity + $$     no beam, no motion'
  Write-Host '     2   Stage 2  controller HTTP API      no beam, no motion'
  Write-Host '     2a  Stage 2  + autofocus probe        MOVES THE HEAD' -ForegroundColor DarkYellow
  Write-Host ''
  Write-Host '     s   sync local copy from the share'
  Write-Host '     e   open the local repo in Explorer'
  Write-Host '     q   quit'
  Write-Host ''
  $c = (Read-Host '   choice').Trim().ToLower()
  if ($c) { Trace ("menu choice: '" + $c + "'") }
  switch ($c) {
    '0'  { Banner; Stage0; Trace 'stage 0 returned' }
    '1'  { Run-Stage 'stage1-serial-probe.ps1' $null;               Trace 'stage 1 returned' }
    '2'  { Run-Stage 'stage2-rest-probe.ps1' $null;                 Trace 'stage 2 returned' }
    '2a' { Run-Stage 'stage2-rest-probe.ps1' @('-AllowAutofocus');  Trace 'stage 2a returned' }
    's'  { Banner; Sync-Local; Read-Host '  Enter' }
    'e'  { Start-Process explorer.exe $script:local }
    'q'  { Trace 'quit'; return }
    default { Write-Host ('   not a choice: ' + $c) -ForegroundColor DarkYellow; Start-Sleep -Milliseconds 900 }
  }
}
