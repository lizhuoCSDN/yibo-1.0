#!/usr/bin/env bash
# 业务侧栏与权限：按依赖顺序一次执行本目录下各 SQL，适合新库或缺菜单/缺角色关联时。
# 不覆盖若依主库自带的「系统管理/监控/工具」等（工具若已删则脚本内 UPDATE 为 0 行）。
#
# 包含能力概览（代码里已有页面/接口；侧栏为动态路由）：
#   - 业务概览 /index 为前端固定路由，不占用 sys_menu
#   - 短信营销(smsMk)：发送页面、模板、短链、数据仓库、敏感词、内容审核（「点击统计」侧栏已隐藏，regroup 会写 visible）
#   - 通道路由(smsOps)：通道、智能路由、新户、线路分配、接口外放(API/SMPP)
#   - 财务(analysis)：消费明细、利润、钱包分析
#   - 无独立侧栏：域名/发送任务（合在「发送页面」内）、/api/sms 开放口、/business/dashboard 旧版若存在可忽略
#   - 与 install_full 的「子目录式」内容审核+敏感词 冲突脚本：content_audit_submenus.sql（二选一，默认用平铺+regroup 方案）
#   - 本链首步 dedupe 用于清理：曾反复执行 install 导致的同 path 重复 C 菜单（见 install_full 注释中的判重说明）
#   - 末步 remove_five：从 sys_menu 删除若依 100-104 及按钮（见 yibo_init_baseline 已同步剔除）；超管读全表，必须库内删行才不再显示
#   - flatten_log：操作日志/登录日志 与 通知公告 同级（挂系统管理下），删「日志管理」父级；旧库多一层目录时由本步纠正
#
# 用法：最后一个参数为数据库名，前面参数原样交给 mysql 客户端（连接/账号/密码等）。
#   ./install_all_business_menus.sh -h 127.0.0.1 -u root -pYourPass yibo
#   或：  ./install_all_business_menus.sh yibo   （使用本机 root 等默认客户端配置）
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [mysql options ...] <database_name>" >&2
  echo "  末步会执行 $DIR/verify_yibo_menu_sanity.sql，非 PASS 则退出 1。仅调试可设: YIBO_SKIP_MENU_VERIFY=1" >&2
  exit 1
fi
DB="${!#}"
MYSQL_ARGS=("${@:1:$#-1}")
run() {
  mysql --default-character-set=utf8mb4 "${MYSQL_ARGS[@]}" "$DB" < "$1"
  echo "  OK: $(basename "$1")" >&2
}
# 与 verify_yibo_menu_sanity.sql 同连接，防「链跑完仍 FAIL」的静默成功
run_menu_sanity_verify() {
  local v
  v="$(
    mysql -N -B --default-character-set=utf8mb4 "${MYSQL_ARGS[@]}" "$DB" < "$DIR/verify_yibo_menu_sanity.sql" 2>/dev/null | tr -d '\r' | tr -d ' ' | grep -E '^(PASS|FAIL)$' | tail -1
  )"
  echo "  menu_sanity: ${v:-}" >&2
  if [[ -z "$v" ]]; then
    echo "  无法解析门禁结果（检查 mysql 与 verify_yibo_menu_sanity.sql 是否存在）" >&2
    return 1
  fi
  if [[ "$v" == "FAIL" ]]; then
    echo "  门禁 FAIL：库中仍存在本链应已清除的侧栏/外链项。勿当成成功发版。调试可: YIBO_SKIP_MENU_VERIFY=1 $0 ..." >&2
    return 1
  fi
  if [[ "$v" == "PASS" ]]; then
    return 0
  fi
  return 1
}
echo "==> DB=$DB  applying business menu chain from $DIR" >&2
run "$DIR/dedupe_sms_business_menus.sql"
run "$DIR/install_full_business_menus.sql"
run "$DIR/regroup_sms_sidebar_menus.sql"
# 原「业务管理」path=business 空壳或子项已迁走后仍残留，必须删 M 行，超管全表拉菜单时否则会一直显示
run "$DIR/promote_business_menus_to_root.sql"
run "$DIR/repair_outbound_menu.sql"
run "$DIR/grant_outbound_to_setting_roles.sql"
run "$DIR/reorder_system_below_finance.sql"
run "$DIR/ensure_admin_role1_all_menus.sql"
run "$DIR/remove_five_system_mgmt_menus.sql"
run "$DIR/remove_monitor_tool_menus.sql"
run "$DIR/flatten_log_menu_under_system.sql"
if [[ "${YIBO_SKIP_MENU_VERIFY:-0}" == "0" ]]; then
  run_menu_sanity_verify || exit 1
else
  echo "==> 已跳过菜单门禁: YIBO_SKIP_MENU_VERIFY=1" >&2
fi
echo "==> Done. Re-login admin user to refresh routers." >&2
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
echo "==> 单独复检: $REPO_ROOT/scripts/verify-yibo-menu-sanity.sh $DB" >&2
