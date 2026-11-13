param([string]$Arquivo = "$PSScriptRoot\flutter_test_resultado.json")
$suites = @{}; $tests = @{}; $res = @()
foreach ($l in Get-Content $Arquivo -Encoding utf8) {
  if (-not $l.StartsWith('{')) { continue }
  $e = $l | ConvertFrom-Json
  switch ($e.type) {
    'suite' { $suites[$e.suite.id] = Split-Path $e.suite.path -Leaf }
    'testStart' { $tests[$e.test.id] = $e.test }
    'testDone' {
      if ($e.hidden) { continue }
      $t = $tests[$e.testID]
      $r = if ($e.skipped) { 'skip' } elseif ($e.result -eq 'success') { 'pass' } else { 'fail' }
      $res += [pscustomobject]@{ Arquivo = $suites[$t.suiteID]; Teste = $t.name; Resultado = $r }
    }
  }
}
$res | Group-Object Arquivo | ForEach-Object {
  [pscustomobject]@{
    Arquivo = $_.Name; Total = $_.Count
    Pass = @($_.Group | ? Resultado -eq 'pass').Count
    Fail = @($_.Group | ? Resultado -eq 'fail').Count
    Skip = @($_.Group | ? Resultado -eq 'skip').Count
  }
} | Format-Table -AutoSize
"TOTAL: $($res.Count)  pass=$(@($res | ? Resultado -eq 'pass').Count)  fail=$(@($res | ? Resultado -eq 'fail').Count)  skip=$(@($res | ? Resultado -eq 'skip').Count)"
"`nFALHAS:"
$res | ? Resultado -eq 'fail' | ForEach-Object { "  [$($_.Arquivo)] $($_.Teste)" }
"`nIGNORADOS:"
$res | ? Resultado -eq 'skip' | ForEach-Object { "  [$($_.Arquivo)] $($_.Teste)" }
