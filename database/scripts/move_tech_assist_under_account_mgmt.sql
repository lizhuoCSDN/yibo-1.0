-- 将「技术协助」挂到「账户管理」下（可重复执行）
-- 需已存在：path=accountMgmt, menu_type=M, parent_id=0
-- 历史曾挂在「系统管理」下，现与侧栏/文案「账户管理-技术协助」一致
SET NAMES utf8mb4;

SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 子顺序：新户(1) -> 敏感词(2) -> 内容审核(3) -> 通知公告(4) -> 技术协助(5)
UPDATE sys_menu SET parent_id = @p_acct, order_num = 5, update_time = NOW()
WHERE @p_acct IS NOT NULL
  AND path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index';

-- 拥有「技术协助」或其 F 级按钮的角色，补挂「账户管理」父目录
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path = 'accountMgmt' AND p.parent_id = 0 AND p.menu_type = 'M'
  AND c.path = 'techAssist' AND c.menu_type = 'C' AND c.component = 'business/techAssist/index';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id) SELECT 1, menu_id
FROM sys_menu WHERE path = 'accountMgmt' AND parent_id = 0 AND menu_type = 'M';

SELECT 'move_tech_assist_under_account_mgmt: done' AS result;
