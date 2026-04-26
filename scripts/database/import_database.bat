@echo off
chcp 65001 >nul
set "REPO=%~dp0..\.."
set "SQLDIR=%REPO%backend\RuoYi-Vue\sql"
set "BASE=%SQLDIR%\yibo_init_baseline.sql"
set "QZ=%SQLDIR%\quartz.sql"
if not exist "%BASE%" (
  echo 未找到: %BASE%
  exit /b 1
)
if not exist "%QZ%" (
  echo 未找到: %QZ%
  exit /b 1
)
rem 若未配置 PATH，可取消下行注释并改成本机路径，例如: set "MYSQL_BIN=C:\tools\mysql\current\bin\mysql.exe"
set "MYSQL_BIN=mysql"
echo 从目录启动 mysql，按提示输入 root 密码；与 application-druid 一致（默认库 yibo）
"%MYSQL_BIN%" -u root -p --default-character-set=utf8mb4 -e "CREATE DATABASE IF NOT EXISTS yibo DEFAULT CHARSET utf8mb4;"
if errorlevel 1 exit /b 1
"%MYSQL_BIN%" -u root -p --default-character-set=utf8mb4 yibo < "%BASE%"
if errorlevel 1 exit /b 1
"%MYSQL_BIN%" -u root -p --default-character-set=utf8mb4 yibo < "%QZ%"
if errorlevel 1 exit /b 1
echo 基线与 Quartz 表已导入。业务菜单可再执行: database\scripts\install_all_business_menus.sh yibo
pause
