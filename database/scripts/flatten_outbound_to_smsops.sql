-- 「API外放」「SMPP外放」与「智能路由」同级挂在「通道路由」下，删除「接口外放」父级目录（可重复执行）
SET NAMES utf8mb4;

SET @p_ops := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 子菜单与按钮的 parent 仍指向 C 型 apikey / smppAccount，只改 C 的 parent_id
UPDATE sys_menu
SET parent_id = @p_ops, order_num = 3, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND path = 'apikey'
  AND menu_type = 'C'
  AND component = 'business/apikey/index';

UPDATE sys_menu
SET parent_id = @p_ops, order_num = 4, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND path = 'smppAccount'
  AND menu_type = 'C'
  AND component = 'business/smppAccount/index';

UPDATE sys_menu
SET order_num = 1, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'channel' AND menu_type = 'C' AND parent_id = @p_ops;
UPDATE sys_menu
SET order_num = 2, update_time = NOW()
WHERE @p_ops IS NOT NULL AND path = 'channelRouter' AND menu_type = 'C' AND parent_id = @p_ops;

UPDATE sys_menu SET remark = '通道/智能路由/API外放/SMPP', update_time = NOW() WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

-- 删除「接口外放」M 及角色关联
SET @oid := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);
DELETE FROM sys_role_menu WHERE @oid IS NOT NULL AND menu_id = @oid;
DELETE FROM sys_menu WHERE @oid IS NOT NULL AND menu_id = @oid;

-- 有通道路由子项的角色补挂 smOps 父菜单
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path = 'smsOps' AND p.parent_id = 0 AND p.menu_type = 'M'
  AND c.path IN ('apikey', 'smppAccount');

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE path = 'smsOps' AND parent_id = 0 AND menu_type = 'M' LIMIT 1;

SELECT 'flatten_outbound_to_smsops: done' AS result;
