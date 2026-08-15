param([string]$BaseUrl = 'http://localhost:8080/commercial-complex-carbon')
$ErrorActionPreference = 'Stop'
if (-not $env:SMOKE_TEST_USERNAME -or -not $env:SMOKE_TEST_PASSWORD) {
  throw 'Set SMOKE_TEST_USERNAME and SMOKE_TEST_PASSWORD before running the smoke test.'
}
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$login = @{username=$env:SMOKE_TEST_USERNAME; password=$env:SMOKE_TEST_PASSWORD} | ConvertTo-Json
$result = [ordered]@{base=$BaseUrl; login=$false; pages=@(); apis=@(); errors=@()}
try {
  $r = Invoke-RestMethod "$BaseUrl/api/auth/login" -Method Post -ContentType 'application/json' -Body $login -WebSession $session
  $result.login = [bool]$r.success
  foreach ($route in @('dashboard','complexes','buildings','areas','merchants','meters','devices','energy','carbon','budget','alerts','tasks','projects','queries','logs','profile')) {
    $p = Invoke-WebRequest "$BaseUrl/app.jsp#/$route" -WebSession $session -UseBasicParsing
    $result.pages += [ordered]@{route=$route; status=$p.StatusCode}
  }
  foreach ($api in @('auth/me','complexes/enabled','dashboard/summary?complexId=1')) {
    $a = Invoke-RestMethod "$BaseUrl/api/$api" -WebSession $session
    $result.apis += [ordered]@{path=$api; success=$a.success}
  }
} catch { $result.errors += $_.Exception.Message }
$result | ConvertTo-Json -Depth 6
