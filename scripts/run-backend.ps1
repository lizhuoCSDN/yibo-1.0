# Start ruoyi-admin; optional one-line password file at repo root: db-password.local (gitignored)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$localPw = Join-Path $root 'db-password.local'
if (Test-Path $localPw) {
  $env:DRUID_MASTER_PASSWORD = (Get-Content $localPw -Raw).Trim()
}
Set-Location (Join-Path $root 'backend\RuoYi-Vue\ruoyi-admin')
mvn spring-boot:run -DskipTests
