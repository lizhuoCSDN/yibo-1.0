@echo off
chcp 65001 > nul
cd /d "%~dp0..\..\frontend\ruoyi-ui"
echo 正在启动前端开发服务器...
call npm run dev

