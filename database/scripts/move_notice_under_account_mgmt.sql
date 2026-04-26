-- 将 RuoYi 标准「通知公告」挂到「账户管理」下（可重复执行）
-- 若依 C 菜单：path=notice, component=system/notice/index
SET NAMES utf8mb4;

SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

UPDATE sys_menu SET parent_id = @p_acct, order_num = 4, update_time = NOW()
WHERE @p_acct IS NOT NULL
  AND path = 'notice' AND menu_type = 'C' AND component = 'system/notice/index';

-- 拥有「账户管理」下任一子菜单的角色补挂 accountMgmt 父目录
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path = 'accountMgmt' AND p.parent_id = 0 AND p.menu_type = 'M';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE path = 'accountMgmt' AND parent_id = 0 AND menu_type = 'M';

SELECT 'move_notice_under_account_mgmt: done' AS result;
