#!/usr/bin/env bash
# 在指定库上跑 database/scripts/verify_yibo_menu_sanity.sql，非 PASS 则 exit 1。
# 例：YIBO_DB=yibo MYSQL_PWD=xxx ./scripts/verify-yibo-menu-sanity.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SQL="$ROOT/database/scripts/verify_yibo_menu_sanity.sql"
DB="${1:-${YIBO_DB:-yibo}}"

[[ -f "$SQL" ]] || { echo "未找到: $SQL" >&2; exit 2; }
command -v mysql >/dev/null 2>&1 || { echo "需要 mysql 客户端" >&2; exit 2; }

export MYSQL_PWD="${MYSQL_PWD:-}"
RES="$(mysql -N -B --default-character-set=utf8mb4 -h "${MYSQL_HOST:-127.0.0.1}" -P "${MYSQL_PORT:-3306}" -u "${MYSQL_USER:-root}" "$DB" < "$SQL" 2>&1)" || {
  echo "$RES" >&2
  exit 2
}
V="$(echo "$RES" | tr -d '\r' | tr -d ' ' | tail -1)"
echo "yibo_menu_sanity: $V ($DB)" >&2
case "$V" in
  PASS) exit 0 ;;
  FAIL)
    echo "提示: 可再执行 database/scripts/install_all_business_menus.sh ... $DB" >&2
    exit 1
    ;;
  *)
    echo "未解析到 PASS/FAIL: [$RES]" >&2
    exit 1
    ;;
esac
