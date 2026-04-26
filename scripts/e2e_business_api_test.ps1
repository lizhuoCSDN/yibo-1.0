# Yibo business API smoke test — routes must match ruoyi-admin controllers under /business/*
# Requires: backend on $BaseUrl, DB reachable, captcha off for login (or valid code/uuid).
# Optional: DRUID_MASTER_PASSWORD etc. for DB (see application-druid.yml).
$ErrorActionPreference = 'Stop'
$BaseUrl = if ($env:E2E_BASE_URL) { $env:E2E_BASE_URL.TrimEnd('/') } else { 'http://127.0.0.1:8080' }

function Invoke-E2EJson {
  param([string]$Method, [string]$Path, [string]$Token = '', [string]$Body = $null)
  $u = "$BaseUrl$Path"
  $h = @{ Accept = 'application/json' }
  if ($Token) { $h['Authorization'] = "Bearer $Token" }
  $p = @{
    Uri = $u
    Method = $Method
    Headers = $h
    TimeoutSec = 30
  }
  if ($null -ne $Body -and $Body -ne '') {
    $p['ContentType'] = 'application/json; charset=utf-8'
    $p['Body'] = $Body
  }
  return Invoke-RestMethod @p
}

Write-Host "== Login ($BaseUrl) ==" -ForegroundColor Cyan
$loginBody = '{"username":"admin","password":"admin123","code":"","uuid":""}'
$login = Invoke-E2EJson -Method POST -Path '/login' -Body $loginBody
if ($login.code -ne 200 -or -not $login.token) {
  throw "Login failed: $($login | ConvertTo-Json -Compress)"
}
$token = $login.token
Write-Host "OK token acquired" -ForegroundColor Green

# Name, Method, Path (query string allowed), optional Body for POST
$tests = @(
  @{ Name = 'getInfo'; Method = 'GET'; Path = '/getInfo' },
  @{ Name = 'dashboard overview'; Method = 'GET'; Path = '/business/dashboard/overview' },
  @{ Name = 'dashboard daily'; Method = 'GET'; Path = '/business/dashboard/daily?days=7' },
  @{ Name = 'channel list'; Method = 'GET'; Path = '/business/channel/list?pageNum=1&pageSize=10' },
  @{ Name = 'channelAssign list'; Method = 'GET'; Path = '/business/channelAssign/list?pageNum=1&pageSize=10' },
  @{ Name = 'apikey list'; Method = 'GET'; Path = '/business/apikey/list?pageNum=1&pageSize=10' },
  @{ Name = 'sendTask list'; Method = 'GET'; Path = '/business/sendTask/list?pageNum=1&pageSize=10' },
  @{ Name = 'sendTask records'; Method = 'GET'; Path = '/business/sendTask/records?pageNum=1&pageSize=10' },
  @{ Name = 'sendTask review list'; Method = 'GET'; Path = '/business/sendTask/review/list?pageNum=1&pageSize=10' },
  @{ Name = 'keyword list'; Method = 'GET'; Path = '/business/keyword/list?pageNum=1&pageSize=10' },
  @{ Name = 'template list'; Method = 'GET'; Path = '/business/template/list?pageNum=1&pageSize=10' },
  @{ Name = 'warehouse list'; Method = 'GET'; Path = '/business/warehouse/list?pageNum=1&pageSize=10' },
  @{ Name = 'finance list'; Method = 'GET'; Path = '/business/finance/list' },
  @{ Name = 'domain list'; Method = 'GET'; Path = '/business/domain/list?pageNum=1&pageSize=10' },
  @{ Name = 'userlink list'; Method = 'GET'; Path = '/business/userlink/list?pageNum=1&pageSize=10' },
  @{ Name = 'userlink statistics'; Method = 'GET'; Path = '/business/userlink/statistics' },
  @{ Name = 'smppAccount list'; Method = 'GET'; Path = '/business/smppAccount/list?pageNum=1&pageSize=10' },
  @{ Name = 'wallet bind options'; Method = 'GET'; Path = '/business/wallet/bind/options' },
  @{ Name = 'wallet bind list'; Method = 'POST'; Path = '/business/wallet/bind/list'; Body = '{"pageNum":1,"pageSize":10}' },
  @{ Name = 'wallet tx list'; Method = 'POST'; Path = '/business/wallet/tx/list'; Body = '{"pageNum":1,"pageSize":10}' },
  @{ Name = 'wallet analyze'; Method = 'GET'; Path = '/business/wallet/analyze?usdtAddress=T9yD14Nj9j7xAB4db_GEiGi9q2_C2D96vC' }
)

$fail = 0
foreach ($t in $tests) {
  try {
    $bodyArg = if ($t.Body) { $t.Body } else { $null }
    $r = Invoke-E2EJson -Method $t.Method -Path $t.Path -Token $token -Body $bodyArg
    $ok = ($r.code -eq 200)
    if (-not $ok) { $fail++ }
    $color = if ($ok) { 'Green' } else { 'Red' }
    $rows = if ($null -ne $r.rows) { $r.rows.Count } else { 'n/a' }
    Write-Host ("[{0}] {1} code={2} rows={3}" -f $(if ($ok) { 'OK' } else { 'FAIL' }), $t.Name, $r.code, $rows) -ForegroundColor $color
  } catch {
    $fail++
    Write-Host ("[FAIL] {0} {1}" -f $t.Name, $_.Exception.Message) -ForegroundColor Red
  }
}

Write-Host "== Done. Failures: $fail / $($tests.Count) ==" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
exit [Math]::Min($fail, 99)
