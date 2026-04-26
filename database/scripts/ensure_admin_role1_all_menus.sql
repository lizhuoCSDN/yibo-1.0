-- 将当前库中所有启用菜单项同步到「超级管理员」角色（role_id=1），可重复执行。
-- 新插入的 M/C/F 若未进 sys_role_menu，管理员在侧栏/按钮权限上会出现缺失；执行本脚本可补齐。
-- 在业务库执行，与 install_full / regroup 等无顺序强依赖，建议放一键安装末尾。
SET NAMES utf8mb4;

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, m.menu_id
FROM sys_menu m
WHERE m.status = '0'
  AND m.menu_id IS NOT NULL;

SELECT 'ensure_admin_role1_all_menus: done' AS result;
