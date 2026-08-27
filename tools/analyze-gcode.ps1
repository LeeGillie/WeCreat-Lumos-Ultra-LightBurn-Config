<#
.SYNOPSIS
    Summarise a G-code file without loading it into memory.

.DESCRIPTION
    Read-only. Streams the file one line at a time, so it is safe on very large
    files (the MakeIt cache is over 200 MB).

    Reports:
      - line count and byte size
      - every distinct G/M code with a count
      - absolute vs relative census: G90/G91 mode switches, and how many motion
        commands were issued in each mode
      - coordinate extents of absolute moves, for comparison against the job's
        own declared bounds or the machine's 210 x 210 field
      - the first and last N lines
      - any ';' header comments found near the top

    Written for the MakeIt-vs-LightBurn comparison: run it on both files and the
    difference in the relative/absolute census is the headline.

.PARAMETER Path
    The .gc / .gcode file to analyse.

.PARAMETER Head
    How many opening lines to show. Default 30.

.PARAMETER Tail
    How many closing lines to show. Default 30.

.EXAMPLE
    .\analyze-gcode.ps1 "$env:APPDATA\Wecreat MakeIt!\gcode\gcode.gc"
    .\analyze-gcode.ps1 'D:\...\captures\Plain Fill.gc'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Path,
    [int] $Head = 30,
    [int] $Tail = 30
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "  Not found: $Path" -ForegroundColor Red
    exit 1
}

$item = Get-Item -LiteralPath $Path
Write-Host ''
Write-Host '  G-code summary (READ-ONLY)' -ForegroundColor Cyan
Write-Host ("  file : {0}" -f $item.FullName)
Write-Host ("  size : {0:N0} bytes    written {1}" -f $item.Length, $item.LastWriteTime)
Write-Host ''
Write-Host '  Streaming... (a 200 MB file takes a minute or two)'

$codes      = @{}
$headLines  = New-Object System.Collections.Generic.List[string]
$tailBuf    = New-Object System.Collections.Generic.Queue[string]
$comments   = New-Object System.Collections.Generic.List[string]

$lineNo       = 0
$relative     = $false
$g90Count     = 0
$g91Count     = 0
$movesAbs     = 0
$movesRel     = 0
$firstG91Line = 0
$lastG91Line  = 0

$minX = [double]::PositiveInfinity; $maxX = [double]::NegativeInfinity
$minY = [double]::PositiveInfinity; $maxY = [double]::NegativeInfinity

$sw     = [System.Diagnostics.Stopwatch]::StartNew()
$reader = [System.IO.File]::OpenText($item.FullName)

try {
    while ($null -ne ($line = $reader.ReadLine())) {
        $lineNo++

        if ($headLines.Count -lt $Head) { $headLines.Add($line) }
        $tailBuf.Enqueue($line)
        if ($tailBuf.Count -gt $Tail) { [void]$tailBuf.Dequeue() }

        $t = $line.Trim()
        if ($t.Length -eq 0) { continue }

        if ($t[0] -eq ';' -or $t[0] -eq '#') {
            if ($comments.Count -lt 25) { $comments.Add($t) }
            continue
        }

        $c = $t[0]
        if ($c -ne 'G' -and $c -ne 'M' -and $c -ne 'g' -and $c -ne 'm') { continue }

        # leading token, e.g. "G1" from "G1X98.05Y107.087"
        $i = 1
        while ($i -lt $t.Length -and [char]::IsDigit($t[$i])) { $i++ }
        if ($i -eq 1) { continue }
        $code = $t.Substring(0, $i).ToUpper()

        if ($codes.ContainsKey($code)) { $codes[$code]++ } else { $codes[$code] = 1 }

        if ($code -eq 'G90') { $relative = $false; $g90Count++; continue }
        if ($code -eq 'G91') {
            $relative = $true; $g91Count++
            if ($firstG91Line -eq 0) { $firstG91Line = $lineNo }
            $lastG91Line = $lineNo
            continue
        }

        if ($code -eq 'G0' -or $code -eq 'G1' -or $code -eq 'G00' -or $code -eq 'G01') {
            if ($relative) {
                $movesRel++
            } else {
                $movesAbs++
                foreach ($m in [regex]::Matches($t, '(?i)([XY])(-?\d+(?:\.\d+)?)')) {
                    $v = [double]$m.Groups[2].Value
                    if ($m.Groups[1].Value -match '(?i)X') {
                        if ($v -lt $minX) { $minX = $v }
                        if ($v -gt $maxX) { $maxX = $v }
                    } else {
                        if ($v -lt $minY) { $minY = $v }
                        if ($v -gt $maxY) { $maxY = $v }
                    }
                }
            }
        }

        if (($lineNo % 500000) -eq 0) {
            Write-Host ("        {0:N0} lines..." -f $lineNo)
        }
    }
}
finally {
    $reader.Close()
    $reader.Dispose()
}

$sw.Stop()

Write-Host ''
Write-Host ("  {0:N0} lines in {1:N1} s" -f $lineNo, $sw.Elapsed.TotalSeconds)
Write-Host ''

# ------------------------------------------------------------ header comments

if ($comments.Count -gt 0) {
    Write-Host '  === Header comments ===' -ForegroundColor Yellow
    foreach ($c in $comments) { Write-Host ("        {0}" -f $c) }
    Write-Host ''
}

# -------------------------------------------------------- absolute / relative

$totalMoves = $movesAbs + $movesRel
Write-Host '  === Absolute vs relative ===' -ForegroundColor Yellow
Write-Host ("        G90 (absolute) switches : {0:N0}" -f $g90Count)
Write-Host ("        G91 (relative) switches : {0:N0}" -f $g91Count)
if ($totalMoves -gt 0) {
    $pctRel = 100.0 * $movesRel / $totalMoves
    $pctAbs = 100.0 * $movesAbs / $totalMoves
    Write-Host ("        moves in ABSOLUTE mode  : {0,12:N0}   ({1,6:N2} %)" -f $movesAbs, $pctAbs)
    Write-Host ("        moves in RELATIVE mode  : {0,12:N0}   ({1,6:N2} %)" -f $movesRel, $pctRel)
} else {
    Write-Host '        (no G0/G1 motion commands found)'
}
if ($firstG91Line -gt 0) {
    Write-Host ("        first G91 at line {0:N0}, last at line {1:N0}" -f $firstG91Line, $lastG91Line)
}
Write-Host ''

if ($movesRel -eq 0 -and $totalMoves -gt 0) {
    Write-Host '        >>> Every motion command in this file is ABSOLUTE.' -ForegroundColor Green
    Write-Host '            A dropped line costs one move, not the rest of the job.'
    Write-Host ''
}

# -------------------------------------------------------------------- extents

if ($movesAbs -gt 0 -and $minX -lt [double]::PositiveInfinity) {
    Write-Host '  === Extents of absolute moves ===' -ForegroundColor Yellow
    Write-Host ("        X  {0,10:N3}  to  {1,10:N3}    span {2,9:N3}" -f $minX, $maxX, ($maxX - $minX))
    Write-Host ("        Y  {0,10:N3}  to  {1,10:N3}    span {2,9:N3}" -f $minY, $maxY, ($maxY - $minY))
    Write-Host '        (compare against the job bounds and the 210 x 210 field)'
    Write-Host ''
}

# ---------------------------------------------------------------- code census

Write-Host '  === Every distinct G/M code ===' -ForegroundColor Yellow
$codes.GetEnumerator() |
    Sort-Object -Property @{Expression = {$_.Value}; Descending = $true} |
    ForEach-Object { Write-Host ('        {0,-6} {1,12:N0}' -f $_.Key, $_.Value) }
Write-Host ''

# ------------------------------------------------------------- head and tail

Write-Host ("  === First {0} lines ===" -f $Head) -ForegroundColor Yellow
foreach ($l in $headLines) { Write-Host ('        {0}' -f $l) }
Write-Host ''

Write-Host ("  === Last {0} lines ===" -f $Tail) -ForegroundColor Yellow
foreach ($l in $tailBuf) { Write-Host ('        {0}' -f $l) }
Write-Host ''
