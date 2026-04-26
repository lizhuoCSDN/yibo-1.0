# Apply database/scripts/rename_menu_statistcis_to_statistics.sql
# Password: repo root db-password.local, or env MYSQL_PWD / default root123456
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$sqlFile = Join-Path $root 'database\scripts\rename_menu_statistcis_to_statistics.sql'
if (-not (Test-Path -LiteralPath $sqlFile)) { throw "Missing: $sqlFile" }

$mysqlExe = $env:MYSQL_CLI
if (-not $mysqlExe -and (Test-Path 'C:\tools\mysql\current\bin\mysql.exe')) {
  $mysqlExe = 'C:\tools\mysql\current\bin\mysql.exe'
}
if (-not $mysqlExe) {
  $w = Get-Command mysql -ErrorAction SilentlyContinue
  if ($w) { $mysqlExe = $w.Source }
}
if (-not $mysqlExe) { throw 'mysql client not found. Set MYSQL_CLI to mysql.exe full path.' }

$pwFile = Join-Path $root 'db-password.local'
$pw = if ($env:MYSQL_PWD) { $env:MYSQL_PWD }
elseif (Test-Path $pwFile) { (Get-Content $pwFile -Raw).Trim() }
else { 'root123456' }

$db = if ($env:MYSQL_DATABASE) { $env:MYSQL_DATABASE } else { 'yibo' }
$dbHost = if ($env:MYSQL_HOST) { $env:MYSQL_HOST } else { '127.0.0.1' }
$dbPort = if ($env:MYSQL_PORT) { $env:MYSQL_PORT } else { '3306' }

Write-Host "Applying to ${db}@${dbHost}:${dbPort} ..." -ForegroundColor Cyan
$env:MYSQL_PWD = $pw
try {
  Get-Content -LiteralPath $sqlFile -Raw -Encoding UTF8 | & $mysqlExe --host=$dbHost --port=$dbPort -uroot $db --default-character-set=utf8mb4
  if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) { throw "mysql exit $LASTEXITCODE" }
  Write-Host 'Done.' -ForegroundColor Green
} finally {
  Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
}
