#!/usr/bin/env bash
# 本地开发：Conda 环境 MySQL + Redis、Spring Boot 后端、环境变量（WSL/无 root 适用）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONDA_SH="${CONDA_SH:-$HOME/miniconda3/etc/profile.d/conda.sh}"
CONDA_ENV="${YIBO_CONDA_ENV:-dbtest}"
JAVA_HOME="${JAVA_HOME:-$HOME/.local/opt/jdk11}"
MAVEN_JAR="$ROOT/backend/RuoYi-Vue/ruoyi-admin/target/ruoyi-admin.jar"
DATA_DIR="${YIBO_DATA_DIR:-$HOME/.yibo}"
PID_DIR="$DATA_DIR"
MYSQL_DATADIR="$DATA_DIR/mysql-data"
MYSQL_SOCK="$DATA_DIR/mysql.sock"
REDIS_DIR="$DATA_DIR/redis"

# JDBC：本地无 SSL 证书时用 useSSL=false
export DRUID_MASTER_URL="${DRUID_MASTER_URL:-jdbc:mysql://127.0.0.1:3306/yibo?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=false&serverTimezone=GMT%2B8}"
export DRUID_MASTER_USERNAME="${DRUID_MASTER_USERNAME:-root}"
export DRUID_MASTER_PASSWORD="${DRUID_MASTER_PASSWORD:-root123456}"

is_listening() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -tln 2>/dev/null | grep -q ":${port} "
    return $?
  fi
  return 1
}

if [[ -f "$CONDA_SH" ]]; then
  # shellcheck source=/dev/null
  source "$CONDA_SH"
  conda activate "$CONDA_ENV"
else
  echo "未找到 Conda: $CONDA_SH（请先按 README 安装 Miniconda 并创建 $CONDA_ENV 环境，内有 mysql-server、redis-server）" >&2
  exit 1
fi

mkdir -p "$PID_DIR" "$REDIS_DIR"

# Redis
if is_listening 6379; then
  echo "Redis 已在 6379 监听，跳过"
else
  nohup redis-server --dir "$REDIS_DIR" --bind 127.0.0.1 --port 6379 --daemonize no >"$DATA_DIR/redis.log" 2>&1 &
  echo $! >"$PID_DIR/redis.pid"
  sleep 1
fi

# MySQL
if is_listening 3306; then
  echo "MySQL 已在 3306 监听，跳过"
else
  if [[ ! -d "$MYSQL_DATADIR/mysql" ]]; then
    mkdir -p "$MYSQL_DATADIR"
    mysqld --no-defaults --initialize-insecure --datadir="$MYSQL_DATADIR"
  fi
  nohup mysqld --no-defaults --datadir="$MYSQL_DATADIR" --socket="$MYSQL_SOCK" --port=3306 --bind-address=127.0.0.1 >"$DATA_DIR/mysql.log" 2>&1 &
  echo $! >"$PID_DIR/mysql.pid"
  sleep 3
fi

if [[ ! -f "$MAVEN_JAR" ]]; then
  echo "未找到 $MAVEN_JAR，请先: cd $ROOT/backend/RuoYi-Vue && mvn -DskipTests package" >&2
  exit 1
fi

if [[ -z "${JAVA_HOME:-}" || ! -x "$JAVA_HOME/bin/java" ]]; then
  echo "请设置 JAVA_HOME 指向 JDK 11+（已安装: $HOME/.local/opt/jdk11）" >&2
  exit 1
fi

export PATH="$JAVA_HOME/bin:$PATH"

if is_listening 8080; then
  echo "端口 8080 已被占用，未启动后端" >&2
else
  nohup java -jar "$MAVEN_JAR" >"$DATA_DIR/ruoyi-backend.log" 2>&1 &
  echo $! >"$PID_DIR/ruoyi-backend.pid"
  echo "后端已启动，日志: $DATA_DIR/ruoyi-backend.log"
fi

cat <<EOF

下一步（首次）：
  mysql -S $MYSQL_SOCK -u root -p'$DRUID_MASTER_PASSWORD' -e "CREATE DATABASE IF NOT EXISTS \`yibo\` DEFAULT CHARSET utf8mb4;"
  mysql -S $MYSQL_SOCK -u root -p'$DRUID_MASTER_PASSWORD' --default-character-set=utf8mb4 yibo < $ROOT/backend/RuoYi-Vue/sql/yibo_init_baseline.sql
  mysql -S $MYSQL_SOCK -u root -p'$DRUID_MASTER_PASSWORD' --default-character-set=utf8mb4 yibo < $ROOT/backend/RuoYi-Vue/sql/quartz.sql
  $ROOT/database/scripts/install_all_business_menus.sh -S $MYSQL_SOCK -u root -p'$DRUID_MASTER_PASSWORD' yibo

启动前端: cd $ROOT/frontend/ruoyi-ui && BROWSER=none port=8081 npm run dev
EOF
