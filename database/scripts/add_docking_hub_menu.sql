-- [已弃用] 曾用于插入「对接向导」菜单。若库中已执行过，请用 remove_docking_hub_menu.sql 回滚。请勿再执行本脚本做新装。
-- 对接向导：侧栏首项 + 子菜单/父级命名更易理解；可重复执行
SET NAMES utf8mb4;

SET @p_ops := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND parent_id = 0 AND menu_type = 'M' LIMIT 1);

-- 子菜单后移，腾出 order_num=1 给「对接向导」
UPDATE sys_menu
SET order_num = order_num + 1, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND parent_id = @p_ops
  AND menu_type = 'C'
  AND path IN ('channel', 'channelRouter', 'apikey', 'smppAccount');

-- 新菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '对接向导', @p_ops, 1, 'dockingHub', 'business/dockingHub/index', 1, 0, 'C', '0', '0', 'business:dockingHub:query', 'guide', 'admin', NOW(),
       '从接供应商、路由、分客户到 HTTP/SMPP 外放'
FROM DUAL
WHERE @p_ops IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'dockingHub' AND menu_type = 'C' AND component = 'business/dockingHub/index');

-- 父级名称（更易理解整组是「接资源 + 外放」）
UPDATE sys_menu SET menu_name = '接供应商与线路外放', remark = '对接向导/供应商通道/智能路由/HTTP与SMPP外放', update_time = NOW()
WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

-- 子菜单显示名
UPDATE sys_menu SET menu_name = '供应商通道', update_time = NOW() WHERE path = 'channel' AND component LIKE 'business/channel/index%';
UPDATE sys_menu SET menu_name = '智能路由(权重/熔断)', update_time = NOW() WHERE path = 'channelRouter' AND component = 'business/channelRouter/index';
UPDATE sys_menu SET menu_name = 'HTTP 外放(AppId)', update_time = NOW() WHERE path = 'apikey' AND component = 'business/apikey/index';
UPDATE sys_menu SET menu_name = 'SMPP 外放账号', update_time = NOW() WHERE path = 'smppAccount' AND component = 'business/smppAccount/index';

-- 有「通道」权限的角色同步挂「对接向导」
SET @mid_dock := (SELECT menu_id FROM sys_menu WHERE path = 'dockingHub' AND menu_type = 'C' LIMIT 1);
SET @mid_ch := (SELECT menu_id FROM sys_menu WHERE path = 'channel' AND menu_type = 'C' LIMIT 1);
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @mid_dock
FROM sys_role_menu r
WHERE @mid_dock IS NOT NULL AND @mid_ch IS NOT NULL AND r.menu_id = @mid_ch;
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) SELECT 1, @mid_dock FROM DUAL WHERE @mid_dock IS NOT NULL;

-- 有 HTTP 外放 / SMPP 外放 菜单权限的角色也挂上对接向导
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @mid_dock
FROM sys_role_menu r
JOIN sys_menu m ON m.menu_id = r.menu_id
WHERE @mid_dock IS NOT NULL
  AND m.path IN ('apikey', 'smppAccount')
  AND m.menu_type = 'C';

SELECT 'add_docking_hub_menu: done' AS result;
