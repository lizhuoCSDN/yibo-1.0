# Phase2: deeper checks using only existing routes (login, getInfo, finance POST, channel, sendTask review, config, wallet).
$ErrorActionPreference = 'Stop'
$BaseUrl = if ($env:E2E_BASE_URL) { $env:E2E_BASE_URL.TrimEnd('/') } else { 'http://127.0.0.1:8080' }

function Invoke-E2EJson {
  param([string]$Method, [string]$Path, [string]$Token = '', [string]$Body = $null)
  $u = "$BaseUrl$Path"
  $h = @{ Accept = 'application/json' }
  if ($Token) { $h['Authorization'] = "Bearer $Token" }
  $p = @{ Uri = $u; Method = $Method; Headers = $h; TimeoutSec = 25 }
  if ($null -ne $Body -and $Body -ne '') {
    $p['ContentType'] = 'application/json; charset=utf-8'
    $p['Body'] = $Body
  }
  return Invoke-RestMethod @p
}

Write-Host "== Phase2 Login ($BaseUrl) ==" -ForegroundColor Cyan
$login = Invoke-E2EJson -Method POST -Path '/login' -Body '{"username":"admin","password":"admin123","code":"","uuid":""}'
if ($login.code -ne 200 -or -not $login.token) { throw "Login failed" }
$token = $login.token
Write-Host "OK token" -ForegroundColor Green

$fail = 0

$r = Invoke-E2EJson -Method GET -Path '/getInfo' -Token $token
if ($r.code -eq 200) { Write-Host "[OK] getInfo" -ForegroundColor Green } else { $fail++; Write-Host "[FAIL] getInfo code=$($r.code)" -ForegroundColor Red }

$r = Invoke-E2EJson -Method POST -Path '/business/finance/balanceLog' -Token $token -Body '{"pageNum":1,"pageSize":5}'
if ($r.code -eq 200) { Write-Host "[OK] finance balanceLog POST" -ForegroundColor Green } else { $fail++; Write-Host "[FAIL] finance balanceLog" -ForegroundColor Red }

$chList = Invoke-E2EJson -Method GET -Path '/business/channel/list?pageNum=1&pageSize=80' -Token $token
$e2eCh = $chList.rows | Where-Object { $_.channelCode -eq 'E2E_CH001' } | Select-Object -First 1
if ($e2eCh -and $e2eCh.id) {
  try {
    $cid = $e2eCh.id
    $balRaw = Invoke-WebRequest -Uri "$BaseUrl/business/channel/balance/$cid" -Headers @{ Authorization = "Bearer $token"; Accept = '*/*' } -UseBasicParsing -TimeoutSec 25
    if ($balRaw.StatusCode -eq 200) {
      Write-Host "[OK] channel balance id=$cid (raw response)" -ForegroundColor Green
    } else {
      $fail++
      Write-Host "[FAIL] channel balance status=$($balRaw.StatusCode)" -ForegroundColor Red
    }
  } catch {
    $fail++
    Write-Host "[FAIL] channel balance $($_.Exception.Message)" -ForegroundColor Red
  }
} else {
  Write-Host "[SKIP] channel E2E_CH001 missing — import e2e seed if you need this check" -ForegroundColor Yellow
}

$rev = Invoke-E2EJson -Method GET -Path '/business/sendTask/review/list?pageNum=1&pageSize=30' -Token $token
if ($rev.code -eq 200) {
  Write-Host "[OK] sendTask review list rows=$($rev.rows.Count)" -ForegroundColor Green
} else {
  $fail++
  Write-Host "[FAIL] review list code=$($rev.code)" -ForegroundColor Red
}

$t1 = $rev.rows | Where-Object { $_.taskNo -eq 'E2E_TSK_REVIEW_001' } | Select-Object -First 1
if ($t1 -and $t1.id) {
  Write-Host "[INFO] seed task E2E_TSK_REVIEW_001 id=$($t1.id) status=$($t1.status)" -ForegroundColor DarkGray
} else {
  Write-Host "[SKIP] E2E_TSK_REVIEW_001 not in list — optional seed data" -ForegroundColor Yellow
}

$r = Invoke-E2EJson -Method GET -Path '/system/config/configKey/sys.account.captchaEnabled' -Token $token
if ($r.code -eq 200) { Write-Host "[OK] config captchaEnabled" -ForegroundColor Green } else { $fail++; Write-Host "[FAIL] config key" -ForegroundColor Red }

$r = Invoke-E2EJson -Method POST -Path '/business/wallet/bind/list' -Token $token -Body '{"pageNum":1,"pageSize":5}'
if ($r.code -eq 200) { Write-Host "[OK] wallet bind list POST" -ForegroundColor Green } else { $fail++; Write-Host "[FAIL] wallet bind list" -ForegroundColor Red }

Write-Host "== Phase2 finished. Failures: $fail ==" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
exit [Math]::Min($fail, 99)
