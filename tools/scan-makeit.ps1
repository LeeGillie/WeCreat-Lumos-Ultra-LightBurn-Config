# scan-makeit.ps1
# Convenience wrapper: inspect a locally installed WeCreat MakeIt! for the Lumos Ultra's
# machine definitions, work modes, and any recoverable G-code vocabulary.
#
# Purpose is interoperability - determining the interface your own hardware expects.
# Nothing extracted here is committed; reference/ is gitignored.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\scan-makeit.ps1 [-Asar <path>] [-Node <path>]

param(
  [string]$Asar = 'C:\Program Files\WeCreat\makeit-builder\resources\app.asar',
  [string]$Node
)

$root = Split-Path $PSScriptRoot -Parent
$out  = Join-Path $root 'reference\makeit-extract'
New-Item -ItemType Directory -Force -Path $out | Out-Null

if (-not $Node) {
  $Node = (Get-Command node -ErrorAction SilentlyContinue).Source
  if (-not $Node) {
    foreach ($c in @('C:\Program Files\nodejs\node.exe','D:\Program Files\nodejs\node.exe')) {
      if (Test-Path $c) { $Node = $c; break }
    }
  }
}
if (-not $Node) { Write-Output 'Node.js not found. Pass -Node <path\to\node.exe>.'; exit 1 }
if (-not (Test-Path $Asar)) { Write-Output ('app.asar not found at: ' + $Asar); exit 1 }

$tool = Join-Path $PSScriptRoot 'asar-tool.js'
$scan = Join-Path $PSScriptRoot 'scan-strings.js'

Write-Output ('MakeIt archive : ' + $Asar)
Write-Output ('  ' + [math]::Round((Get-Item $Asar).Length / 1MB, 1) + ' MB, modified ' + (Get-Item $Asar).LastWriteTime)
Write-Output ''

Write-Output '=== Lumos Ultra work modes (the vendor mode inventory) ==='
& $Node $tool list $Asar 'lumosUltra'

Write-Output ''
Write-Output '=== Generic work modes, for comparison ==='
& $Node $tool list $Asar 'workMode/'

Write-Output ''
Write-Output '=== Application code layout ==='
& $Node $tool list $Asar 'laser-builder/main'
& $Node $tool list $Asar 'laser-builder/preload'

Write-Output ''
Write-Output '=== Extracting bytecode bundles for string analysis ==='
& $Node $tool extract $Asar 'packages/laser-builder/main/dist/index.jsc'    (Join-Path $out 'main-index.jsc')
& $Node $tool extract $Asar 'packages/laser-builder/preload/dist/index.jsc' (Join-Path $out 'preload-index.jsc')

Write-Output ''
Write-Output '=== String sweep: machine vocabulary ==='
& $Node $scan (Join-Path $out 'main-index.jsc') '(ultra|lumos|crystal|mopa|conveyor|slider|rotary|galvo|lens)' 4 200

Write-Output ''
Write-Output '=== String sweep: gcode tokens ==='
& $Node $scan (Join-Path $out 'main-index.jsc') '^[MG][0-9]{1,3}[SXYZABF][0-9.-]' 3 200

Write-Output ''
Write-Output '=== String sweep: HTTP endpoints ==='
& $Node $scan (Join-Path $out 'main-index.jsc') '^/(device|process|camera|test|system|file|api)/' 5 200

Write-Output ''
Write-Output 'NOTE: as of MakeIt 3.0.6 these sweeps come back empty. The application logic lives in'
Write-Output '      packages/laser-builder/main/dist/f.enc, which is ENCRYPTED, and the .jsc bundles'
Write-Output '      are V8 bytecode. Static extraction of the M-code table is not possible.'
Write-Output '      See docs/11-makeit-internals.md. Use live capture (bring-up Stage 5) instead.'
