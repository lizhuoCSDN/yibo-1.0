#!/usr/bin/env bash
# 代码库 +（可选）当前库 菜单门禁：防配置/脚本里又写回 ry、误留 dump 等。
# 用法：./scripts/yibo-drift-audit.sh [数据库名]   默认可用 YIBO_DB 或 yibo
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BAD=0
DBNAME="${1:-${YIBO_DB:-yibo}}"

echo "==> 仓库: $ROOT" >&2
echo "==> 1) 扫描易诱发连错库/灌错库的片段（略过 node_modules、target、dist）" >&2
HIT="$(
  grep -R -n -E '3306/ry|/ry\?|USE ry;|ry_20250522|local-20[0-9_]+_21_[0-9_]+-dump' \
    --include='*.yml' --include='*.yaml' --include='*.sh' --include='*.properties' \
    --include='*.bat' --include='*.ps1' --include='*.md' --include='*.sql' \
    --exclude='yibo-drift-audit.sh' \
    --exclude-dir=node_modules --exclude-dir=target --exclude-dir=dist --exclude-dir=.git \
    "$ROOT" 2>/dev/null | head -40 || true
)"
if [[ -n "$HIT" ]]; then
  echo "  [FAIL] 发现可疑行（请逐条处理）:" >&2
  echo "$HIT" >&2
  BAD=1
else
  echo "  [OK] 未见常见旧库名/旧 dump 指纹" >&2
fi

echo "==> 2) database/dumps 下是否仍有 *.sql" >&2
shopt -s nullglob
DUMPS=("$ROOT/database/dumps"/*.sql)
if [[ ${#DUMPS[@]} -gt 0 ]]; then
  echo "  [WARN] 发现 ${#DUMPS[@]} 个 .sql 文件（大 dump 易误用）" >&2
  ls -la "${DUMPS[@]}" >&2
  BAD=1
else
  echo "  [OK] 无 .sql" >&2
fi

echo "==> 3) 菜单只读门禁（需 mysql 能连，库: $DBNAME ）" >&2
if command -v mysql >/dev/null 2>&1; then
  if "$ROOT/scripts/verify-yibo-menu-sanity.sh" "$DBNAME" >&2; then
    echo "  [OK] verify PASS" >&2
  else
    echo "  [FAIL] verify" >&2
    BAD=1
  fi
else
  echo "  [SKIP] 无 mysql 客户端" >&2
fi

if [[ "$BAD" -ne 0 ]]; then
  echo "==> 汇总: 需处理上述项。说明见: docs/数据与发版防回退.md" >&2
  exit 1
fi
echo "==> 汇总: OK" >&2
exit 0
