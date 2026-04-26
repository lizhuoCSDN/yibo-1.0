@echo off
chcp 65001 > nul
cd /d "%~dp0..\..\backend\RuoYi-Vue\ruoyi-admin"
echo 正在启动后端 (Spring Boot)...
call mvn spring-boot:run

