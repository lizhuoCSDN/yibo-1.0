#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="${SCRIPT_DIR}/promote_business_menus_to_root.sql"

# 与 ruoyi-admin application-druid.yml 中默认值一致；可用环境变量覆盖
: "${DRUID_MASTER_URL:=jdbc:mysql://localhost:3306/yibo?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8}"
: "${DRUID_MASTER_USERNAME:=root}"
: "${DRUID_MASTER_PASSWORD:=root123456}"

# 从 jdbc url 中解析 host/port/db（简单处理默认 jdbc:mysql://host:port/db?...）
db_host=localhost
db_port=3306
db_name=yibo
if [[ "${DRUID_MASTER_URL}" =~ jdbc:mysql://([^:/]+):([0-9]+)/([^?]+) ]]; then
  db_host="${BASH_REMATCH[1]}"
  db_port="${BASH_REMATCH[2]}"
  db_name="${BASH_REMATCH[3]}"
fi

if ! command -v mysql >/dev/null 2>&1; then
  echo "未找到 mysql 命令行客户端。请安装: sudo apt install mysql-client" >&2
  echo "或在已安装 MySQL 客户端的环境执行: mysql ... < \"${SQL_FILE}\"" >&2
  exit 1
fi

echo "执行: ${SQL_FILE} -> ${db_host}:${db_port}/${db_name} 用户=${DRUID_MASTER_USERNAME}"
mysql -h "$db_host" -P "$db_port" -u "$DRUID_MASTER_USERNAME" -p"$DRUID_MASTER_PASSWORD" "$db_name" < "$SQL_FILE"
echo "完成 (exit 0.)"
