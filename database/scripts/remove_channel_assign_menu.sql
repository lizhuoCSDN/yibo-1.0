-- 删除侧栏「线路分配」独立菜单（新户管理内已含线路分配；可重复执行，已删则 0 行）
SET NAMES utf8mb4;

SET @aid := (
  SELECT menu_id FROM sys_menu
  WHERE path = 'channelAssign' AND menu_type = 'C' AND component = 'business/channelAssign/index'
  LIMIT 1
);

-- 子按钮/权限（若存在 F）
DELETE r FROM sys_role_menu r
INNER JOIN sys_menu m ON m.menu_id = r.menu_id
WHERE @aid IS NOT NULL AND m.parent_id = @aid;

DELETE FROM sys_menu WHERE @aid IS NOT NULL AND parent_id = @aid;

DELETE FROM sys_role_menu WHERE @aid IS NOT NULL AND menu_id = @aid;
DELETE FROM sys_menu WHERE @aid IS NOT NULL AND menu_id = @aid;

-- 账户管理下顺序：新户(1) 敏感词(2) 内容审核(3)
SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

UPDATE sys_menu SET order_num = 1, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'newUser' AND menu_type = 'C' AND parent_id = @p_acct;
UPDATE sys_menu SET order_num = 2, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'keyword' AND menu_type = 'C' AND parent_id = @p_acct;
UPDATE sys_menu SET order_num = 3, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'contentReview' AND menu_type = 'C' AND parent_id = @p_acct;

UPDATE sys_menu SET remark = '新户/敏感词/内容审核', update_time = NOW()
WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0;

SELECT 'remove_channel_assign_menu: done' AS result;
