#!/usr/bin/env bash
# 若未启动则拉齐：Conda 环境、Redis、MySQL、后端(8080)、前端(8081)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
CONDA_ENV="${YIBO_CONDA_ENV:-dbtest}"
JAVA_HOME="${JAVA_HOME:-$HOME/.local/opt/jdk11}"
JAR="$ROOT/backend/RuoYi-Vue/ruoyi-admin/target/ruoyi-admin.jar"
DATA_DIR="${YIBO_DATA_DIR:-$HOME/.yibo}"
export DRUID_MASTER_URL="${DRUID_MASTER_URL:-jdbc:mysql://127.0.0.1:3306/yibo?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=false&serverTimezone=GMT%2B8}"
export DRUID_MASTER_PASSWORD="${DRUID_MASTER_PASSWORD:-root123456}"
export DRUID_MASTER_USERNAME="${DRUID_MASTER_USERNAME:-root}"
MYSQL_DATADIR="$DATA_DIR/mysql-data"
MYSQL_SOCK="$DATA_DIR/mysql.sock"
REDIS_DIR="$DATA_DIR/redis"

is_listening() { ss -tln 2>/dev/null | grep -q ":$1 " || return 1; return 0; }

[[ -f "$CONDA_SH" ]] || { echo "缺少 Conda: $CONDA_SH" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONDA_SH"
conda activate "$CONDA_ENV"
mkdir -p "$DATA_DIR" "$REDIS_DIR"

if ! is_listening 6379; then
  nohup redis-server --dir "$REDIS_DIR" --bind 127.0.0.1 --port 6379 --daemonize no >"$DATA_DIR/redis.log" 2>&1 &
  echo $! >"$DATA_DIR/redis.pid"
  sleep 1
  echo "已启动 Redis"
fi

if ! is_listening 3306; then
  if [[ ! -d "$MYSQL_DATADIR/mysql" ]]; then
    mkdir -p "$MYSQL_DATADIR"
    mysqld --no-defaults --initialize-insecure --datadir="$MYSQL_DATADIR"
  fi
  nohup mysqld --no-defaults --datadir="$MYSQL_DATADIR" --socket="$MYSQL_SOCK" --port=3306 --bind-address=127.0.0.1 >"$DATA_DIR/mysql.log" 2>&1 &
  echo $! >"$DATA_DIR/mysql.pid"
  sleep 3
  echo "已启动 MySQL"
  if ! mysql -S "$MYSQL_SOCK" -u root -e "USE yibo" 2>/dev/null; then
    mysql -S "$MYSQL_SOCK" -u root -e "CREATE DATABASE IF NOT EXISTS \`yibo\` DEFAULT CHARACTER SET utf8mb4; ALTER USER 'root'@'localhost' IDENTIFIED BY '$DRUID_MASTER_PASSWORD'; FLUSH PRIVILEGES;" 2>/dev/null || true
    echo "已创建库 yibo。首次请导入: $ROOT/backend/RuoYi-Vue/sql/yibo_init_baseline.sql 与 quartz.sql，再执行 database/scripts/install_all_business_menus.sh" >&2
  fi
fi

if [[ -x "$JAVA_HOME/bin/java" && -f "$JAR" ]] && ! is_listening 8080; then
  export PATH="$JAVA_HOME/bin:$PATH"
  nohup java -jar "$JAR" >"$DATA_DIR/ruoyi-backend.log" 2>&1 &
  echo $! >"$DATA_DIR/ruoyi-backend.pid"
  for _ in {1..30}; do is_listening 8080 && break; sleep 1; done
  echo "已启动后端 -> http://127.0.0.1:8080"
fi

UI="$ROOT/frontend/ruoyi-ui"
if is_listening 8081; then
  echo "前端已在 8081 监听，跳过"
else
  if [[ -d "$UI/node_modules" ]]; then
    ( cd "$UI" && BROWSER=none port=8081 nohup npm run dev >"$DATA_DIR/ruoyi-frontend.log" 2>&1 & echo $! >"$DATA_DIR/ruoyi-frontend.pid" )
    for _ in {1..45}; do is_listening 8081 && break; sleep 1; done
    echo "已启动前端 -> http://127.0.0.1:8081"
  else
    echo "缺少 node_modules，请在 frontend/ruoyi-ui 执行: npm install" >&2
  fi
fi

echo "---"
curl -s -o /dev/null -w "8080 HTTP %{http_code}\n" http://127.0.0.1:8080/ || true
curl -s -o /dev/null -w "8081 HTTP %{http_code}\n" http://127.0.0.1:8081/ || true
