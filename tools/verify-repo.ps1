$root = Split-Path $PSScriptRoot -Parent

Write-Output '=========== 1. Schema check: our profile vs the vendor Lumos profile ==========='
$vend = Join-Path $root 'reference\vendor-lbdev\WeCreat-Lumos-v1.5.lbdev'
$ours = Join-Path $root 'profiles\draft\WeCreat-Lumos-Ultra-UV-Purple-210.lbdev'
if ((Test-Path $vend) -and (Test-Path $ours)) {
  $v = (Get-Content $vend -Raw | ConvertFrom-Json).DeviceList[0]
  $o = (Get-Content $ours -Raw | ConvertFrom-Json).DeviceList[0]

  $vTop = $v.PSObject.Properties.Name | Sort-Object
  $oTop = $o.PSObject.Properties.Name | Sort-Object
  Write-Output ('  top-level keys : vendor=' + $vTop.Count + '  ours=' + $oTop.Count)
  $missTop = $vTop | Where-Object { $oTop -notcontains $_ }
  $extraTop = $oTop | Where-Object { $vTop -notcontains $_ }
  if ($missTop)  { Write-Output ('  MISSING vs vendor : ' + ($missTop -join ', ')) } else { Write-Output '  MISSING vs vendor : none' }
  if ($extraTop) { Write-Output ('  EXTRA   vs vendor : ' + ($extraTop -join ', ')) } else { Write-Output '  EXTRA   vs vendor : none' }

  $vSet = $v.Settings.PSObject.Properties.Name | Sort-Object
  $oSet = $o.Settings.PSObject.Properties.Name | Sort-Object
  Write-Output ('  Settings keys  : vendor=' + $vSet.Count + '  ours=' + $oSet.Count)
  $missSet = $vSet | Where-Object { $oSet -notcontains $_ }
  $extraSet = $oSet | Where-Object { $vSet -notcontains $_ }
  if ($missSet)  { Write-Output ('  MISSING vs vendor : ' + ($missSet -join ', ')) } else { Write-Output '  MISSING vs vendor : none' }
  if ($extraSet) { Write-Output ('  EXTRA   vs vendor : ' + ($extraSet -join ', ')) } else { Write-Output '  EXTRA   vs vendor : none' }
} else {
  Write-Output '  (vendor reference not present - run tools\fetch-vendor-lbdev.ps1)'
}

Write-Output ''
Write-Output '=========== 2. Relative markdown links resolve ==========='
$broken = 0; $checked = 0
Get-ChildItem $root -Recurse -Filter *.md -File |
  Where-Object { $_.FullName -notmatch '\\reference\\(vendor-lbdev|makeit-extract)\\' } |
  ForEach-Object {
    $dir = $_.DirectoryName
    $rel = $_.FullName.Substring($root.Length + 1)
    foreach ($m in [regex]::Matches((Get-Content $_.FullName -Raw), '\]\(([^)]+)\)')) {
      $t = $m.Groups[1].Value
      if ($t -match '^(https?:|mailto:|#)') { continue }
      $t = ($t -split '#')[0]
      if (-not $t) { continue }
      $checked++
      $p = Join-Path $dir ($t -replace '/', '\')
      if (-not (Test-Path $p)) { Write-Output ('  BROKEN  ' + $rel + '  ->  ' + $t); $broken++ }
    }
  }
Write-Output ('  checked ' + $checked + ' relative links, ' + $broken + ' broken')

Write-Output ''
Write-Output '=========== 3. No unverified M-codes anywhere in profiles ==========='
$hits = Select-String -Path (Join-Path $root 'profiles\draft\*.lbdev') -Pattern '"(StartGCode|EndGCode|Macro\d_Content)":\s*"[^"]+"' -AllMatches
if ($hits) { $hits | ForEach-Object { Write-Output ('  FOUND  ' + $_.Filename + ': ' + $_.Line.Trim()) } }
else { Write-Output '  clean - all start/end G-code and macros are empty' }

Write-Output ''
Write-Output '=========== 4. Vendor material is not tracked by git ==========='
Set-Location $root
$tracked = git ls-files | Select-String -Pattern 'vendor-lbdev/|makeit-extract/|\.asar$|\.jsc$|\.enc$|WeCreat-(Vision|Vista)[^/]*\.lbdev$|WeCreat-Lumos-v[0-9]'
if ($tracked) { Write-Output ('  PROBLEM: ' + ($tracked -join ', ')) } else { Write-Output '  clean - no vendor files tracked' }

Write-Output ''
Write-Output '=========== 5. Profiles regenerate identically (spec/output drift) ==========='
& (Join-Path $root 'tools\build-profiles.ps1') | Out-Null
$drift = git status --porcelain profiles/
if ($drift) { Write-Output ('  DRIFT: ' + $drift) } else { Write-Output '  clean - committed profiles match the spec' }
