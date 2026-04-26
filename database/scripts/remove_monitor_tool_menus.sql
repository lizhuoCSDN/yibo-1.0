-- 删除侧栏「系统监控」下：定时任务、数据监控(Druid)、服务监控、缓存监控、缓存列表（及任务子按钮），
-- 并删除空目录「系统监控」；「在线用户」挂到「系统管理」下（与 backend/RuoYi-Vue/sql/move_online_user_remove_monitor.sql 一致）。
-- 超管读全表 sys_menu，必须从库删行；可重复执行（已删则影响 0 行）。
SET NAMES utf8mb4;

UPDATE sys_menu
SET parent_id = 1, order_num = 10, path = 'online', component = 'system/online/index', perms = 'system:online:list', remark = '在线用户菜单'
WHERE menu_id = 109;

UPDATE sys_menu SET perms = 'system:online:query' WHERE menu_id = 1046;
UPDATE sys_menu SET perms = 'system:online:batchLogout' WHERE menu_id = 1047;
UPDATE sys_menu SET perms = 'system:online:forceLogout' WHERE menu_id = 1048;

DELETE FROM sys_role_menu WHERE menu_id IN (2, 110, 111, 112, 113, 114, 1049, 1050, 1051, 1052, 1053, 1054);

DELETE FROM sys_menu WHERE menu_id IN (1049, 1050, 1051, 1052, 1053, 1054);
DELETE FROM sys_menu WHERE menu_id IN (110, 111, 112, 113, 114);
DELETE FROM sys_menu WHERE menu_id = 2;

UPDATE sys_menu SET order_num = 2 WHERE menu_id = 4 AND parent_id = 0;

SELECT 'remove_monitor_tool_menus: done' AS result;
