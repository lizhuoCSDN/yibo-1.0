-- 新增顶级「账户管理」(accountMgmt)；其下：新户管理、敏感词页、内容审核、通知公告、技术协助（线路分配已在新户内，不单独挂侧栏）（可重复执行）
SET NAMES utf8mb4;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '账户管理', 0, 21, 'accountMgmt', 'Layout', 1, 0, 'M', '0', '0', '', 'peoples', 'admin', NOW(), '新户/敏感词/内容审核/通知公告/技术协助'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0);

SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
SET @p_ops  := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

UPDATE sys_menu SET component = 'Layout', menu_name = '账户管理', remark = '新户/敏感词/内容审核/通知公告/技术协助', update_time = NOW()
WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0;

-- 子菜单归到「账户管理」
UPDATE sys_menu SET parent_id = @p_acct, order_num = 1, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'newUser' AND menu_type = 'C' AND component = 'business/newUser/index';

UPDATE sys_menu SET parent_id = @p_acct, order_num = 2, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'keyword' AND menu_type = 'C' AND component = 'business/keyword/index';

UPDATE sys_menu SET parent_id = @p_acct, order_num = 3, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'contentReview' AND menu_type = 'C' AND component = 'business/contentReview/index';

UPDATE sys_menu SET parent_id = @p_acct, order_num = 4, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'notice' AND menu_type = 'C' AND component = 'system/notice/index';

UPDATE sys_menu SET parent_id = @p_acct, order_num = 5, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index';

-- 「通道路由」：通道/智能路由/API外放/SMPP（与 flatten_outbound_to_smsops.sql 一致）
UPDATE sys_menu SET order_num = 1, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'channel' AND menu_type = 'C' AND parent_id = @p_ops;

UPDATE sys_menu SET order_num = 2, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'channelRouter' AND menu_type = 'C' AND parent_id = @p_ops;

UPDATE sys_menu SET parent_id = @p_ops, order_num = 3, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'apikey' AND menu_type = 'C' AND component = 'business/apikey/index';

UPDATE sys_menu SET parent_id = @p_ops, order_num = 4, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'smppAccount' AND menu_type = 'C' AND component = 'business/smppAccount/index';

SET @outbound_rm := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);
DELETE FROM sys_role_menu WHERE @outbound_rm IS NOT NULL AND menu_id = @outbound_rm;
DELETE FROM sys_menu WHERE @outbound_rm IS NOT NULL AND menu_id = @outbound_rm;

UPDATE sys_menu SET remark = '通道/智能路由/API外放/SMPP', update_time = NOW() WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

-- 顶级顺序：短信营销(10) < 账户管理(11) < 通道路由(12)
UPDATE sys_menu SET order_num = 10 WHERE path = 'smsMk'   AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 11 WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 12 WHERE path = 'smsOps'  AND menu_type = 'M' AND parent_id = 0;

-- 有子项的角色补挂「账户管理」父菜单
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path = 'accountMgmt' AND p.parent_id = 0 AND p.menu_type = 'M';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE path = 'accountMgmt' AND parent_id = 0 AND menu_type = 'M';

-- 删除独立「线路分配」侧栏项（同 remove_channel_assign_menu.sql）
SET @aid := (
  SELECT menu_id FROM sys_menu
  WHERE path = 'channelAssign' AND menu_type = 'C' AND component = 'business/channelAssign/index'
  LIMIT 1
);
DELETE r FROM sys_role_menu r
INNER JOIN sys_menu m ON m.menu_id = r.menu_id
WHERE @aid IS NOT NULL AND m.parent_id = @aid;
DELETE FROM sys_menu WHERE @aid IS NOT NULL AND parent_id = @aid;
DELETE FROM sys_role_menu WHERE @aid IS NOT NULL AND menu_id = @aid;
DELETE FROM sys_menu WHERE @aid IS NOT NULL AND menu_id = @aid;

SELECT 'add_account_management_menu_group: done' AS result;
