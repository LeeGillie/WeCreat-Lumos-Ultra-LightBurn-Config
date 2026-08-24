# fetch-vendor-lbdev.ps1
# Downloads WeCreat's official LightBurn device profiles into the gitignored reference/ area,
# for structural comparison. These files are NOT redistributed by this repository.
# Source page: https://wecreat.com/pages/software
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\fetch-vendor-lbdev.ps1

$root = Split-Path $PSScriptRoot -Parent
$dest = Join-Path $root 'reference\vendor-lbdev'
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$cdn = 'https://cdn.shopify.com/s/files/1/0734/9773/9561/files/'

$files = @(
  @{ Name = 'WeCreat-Lumos-v1.5.lbdev';      Url = $cdn + 'WeCreat-Lumos-v1.5.lbdev?v=1754041991' },
  @{ Name = 'WeCreat-Vision-V1.0.lbdev';     Url = $cdn + 'WeCreat-Vision-V1.0.lbdev?v=1747721983' },
  @{ Name = 'WeCreat-Vision_Pro-V1.0.lbdev'; Url = $cdn + 'WeCreat-Vision_Pro-V1.0.lbdev?v=1747720648' },
  @{ Name = 'WeCreat-Vista-V1.0.lbdev';      Url = $cdn + 'WeCreat-Vista-V1.0.lbdev?v=1747720649' },
  @{ Name = 'WECREAT-LC.lbdev';              Url = $cdn + 'WECREAT-LC.lbdev' }
)

Write-Output ('Downloading ' + $files.Count + ' vendor profiles to ' + $dest)
foreach ($f in $files) {
  $out = Join-Path $dest $f.Name
  try {
    Invoke-WebRequest -Uri $f.Url -OutFile $out -UseBasicParsing
    Write-Output ('  OK    {0}  ({1} bytes)' -f $f.Name, (Get-Item $out).Length)
  } catch {
    Write-Output ('  FAIL  {0}  : {1}' -f $f.Name, $_.Exception.Message)
  }
}
Write-Output ''
Write-Output 'There is deliberately no Lumos Ultra entry here - WeCreat does not publish one.'
Write-Output 'That absence is why this project exists.'
