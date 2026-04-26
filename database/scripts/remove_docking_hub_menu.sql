-- 去掉「对接向导」菜单、恢复子菜单 order 与名称（与 regroup 前一致，可重复执行）
SET NAMES utf8mb4;

SET @p_ops := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND parent_id = 0 AND menu_type = 'M' LIMIT 1);
SET @mid_dock := (SELECT menu_id FROM sys_menu WHERE path = 'dockingHub' AND menu_type = 'C' AND component = 'business/dockingHub/index' LIMIT 1);

DELETE FROM sys_role_menu WHERE @mid_dock IS NOT NULL AND menu_id = @mid_dock;
DELETE FROM sys_menu WHERE @mid_dock IS NOT NULL AND menu_id = @mid_dock;

-- 子菜单 order 恢复：仅当本脚本删除了「对接向导」时前移 1，避免重复执行时乱序
UPDATE sys_menu
SET order_num = GREATEST(order_num - 1, 0), update_time = NOW()
WHERE @mid_dock IS NOT NULL
  AND @p_ops IS NOT NULL
  AND parent_id = @p_ops
  AND menu_type = 'C'
  AND path IN ('channel', 'channelRouter', 'apikey', 'smppAccount');

-- 父级/子级名称（与 regroup 文案一致）
UPDATE sys_menu
SET menu_name = '通道路由', remark = '通道/智能路由/API外放/SMPP', update_time = NOW()
WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

UPDATE sys_menu SET menu_name = '通道管理', update_time = NOW() WHERE path = 'channel' AND menu_type = 'C' AND (component LIKE 'business/channel/index%' OR component = 'business/channel/index');
UPDATE sys_menu SET menu_name = '智能路由', update_time = NOW() WHERE path = 'channelRouter' AND menu_type = 'C' AND component = 'business/channelRouter/index';
UPDATE sys_menu SET menu_name = 'API 外放', update_time = NOW() WHERE path = 'apikey' AND menu_type = 'C' AND component = 'business/apikey/index';
UPDATE sys_menu SET menu_name = 'SMPP 外放', update_time = NOW() WHERE path = 'smppAccount' AND menu_type = 'C' AND component = 'business/smppAccount/index';

SELECT 'remove_docking_hub_menu: done' AS result;
