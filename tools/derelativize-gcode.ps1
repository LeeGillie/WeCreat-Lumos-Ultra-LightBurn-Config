<#
  derelativize-gcode.ps1

  Convert LightBurn's G91 relative raster moves into G90 absolute coordinates.

  WHY THIS EXISTS
  ---------------
  LightBurn emits fills as long runs of G91 relative moves - 99.97% of a Plain
  Fill job, with only two absolute re-anchors in the whole file. That is a
  bandwidth optimisation and it is normally harmless.

  On the Lumos Ultra it is not harmless. The controller's stream stalls, and the
  recovery (Pause/Resume) can lose or truncate a move. In relative mode every
  later position inherits that error permanently - measured at 2.3 mm outside
  the job's own bounding box, and unbounded in principle.

  Rewriting the file in absolute coordinates does not fix the stalls. It makes
  them SURVIVABLE: a lost line becomes one missing segment instead of a ruined
  workpiece, because the very next line states where the beam should be.

  See captures/stage5-G91-relative-mode-CONFIRMED.md and
      captures/stage5-drift-measured-and-pause-harm.md

  USAGE
  -----
    .\derelativize-gcode.ps1 -Path "job.gc"
    .\derelativize-gcode.ps1 -Path "job.gc" -OutFile "job-absolute.gc"

  Then in LightBurn use **Run GCode** to send the converted file.

  The converted file is larger - absolute coordinates are longer strings than
  deltas. That is the trade being made deliberately.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string] $Path,
  [string] $OutFile
)

$src = Get-Item -LiteralPath $Path -ErrorAction Stop
if (-not $OutFile) {
  $OutFile = Join-Path $src.DirectoryName ($src.BaseName + ' - absolute' + $src.Extension)
}

$relative = $false
$x = 0.0
$y = 0.0
$converted = 0
$out = New-Object System.Collections.Generic.List[string]

foreach ($line in [System.IO.File]::ReadLines($src.FullName)) {
  $s = $line.Trim()

  if ($s -match '^G91\b') {
    $relative = $true
    $out.Add(';G91 removed by derelativize-gcode.ps1')
    continue
  }
  if ($s -match '^G90\b') {
    $relative = $false
    $out.Add($line)
    continue
  }
  if ($s -notmatch '^(G0|G1)\b') {
    $out.Add($line)
    continue
  }

  $cmd = $Matches[1]
  $rest = $s.Substring($cmd.Length)

  $hasX = $rest -match 'X(-?\d*\.?\d+)'
  $vx = if ($hasX) { [double]$Matches[1] } else { $null }
  $hasY = $rest -match 'Y(-?\d*\.?\d+)'
  $vy = if ($hasY) { [double]$Matches[1] } else { $null }

  if ($relative) {
    if ($hasX) { $x += $vx }
    if ($hasY) { $y += $vy }
    # strip the coordinate words, keep S / F / everything else
    $tail = [regex]::Replace($rest, '[XYZ]-?\d*\.?\d+', '')
    $out.Add(('{0} X{1:F4} Y{2:F4}{3}' -f $cmd, $x, $y, $tail))
    $converted++
  } else {
    if ($hasX) { $x = $vx }
    if ($hasY) { $y = $vy }
    $out.Add($line)
  }
}

[System.IO.File]::WriteAllLines($OutFile, $out, (New-Object System.Text.UTF8Encoding $false))

Write-Host ''
Write-Host ("  converted {0} relative moves to absolute" -f $converted) -ForegroundColor Green
Write-Host ("  final tracked position: X{0:F3} Y{1:F3}" -f $x, $y)
Write-Host ("  written: {0}" -f $OutFile) -ForegroundColor Cyan
Write-Host ''
Write-Host '  Sanity check: the coordinate range of the output should match the' -ForegroundColor DarkGray
Write-Host '  ";Bounds:" comment on line 3 of the source. If it does not, do not run it.' -ForegroundColor DarkGray
Write-Host ''
