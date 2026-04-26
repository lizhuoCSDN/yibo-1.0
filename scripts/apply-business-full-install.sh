#!/usr/bin/env bash
# 在 yibo 上执行：全量业务表 + 业务菜单 + 外放子菜单（与 install_full_business_*.sql 一致）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCR="$ROOT/database/scripts"
: "${MYSQL_SOCK:=$HOME/.yibo/mysql.sock}"
: "${MYSQL_PWD:=root123456}"
export MYSQL_PWD
mysql() { command mysql -S "$MYSQL_SOCK" -u root --default-character-set=utf8mb4 -p"$MYSQL_PWD" "$@"; }

echo "== install_full_business_schema =="
mysql yibo < "$SCR/install_full_business_schema.sql"
echo "== install_full_business_menus =="
mysql yibo < "$SCR/install_full_business_menus.sql"
echo "== repair_outbound_menu =="
mysql yibo < "$SCR/repair_outbound_menu.sql"
echo "== done. 请重启后端后重新登录。"
