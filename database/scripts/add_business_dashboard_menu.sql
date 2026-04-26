-- 【已废弃】业务概览已改为固定路由 /index（views/index.vue），请用 remove_dashboard_business_menu.sql 清理旧菜单。
-- 以下历史脚本仅作存档，新环境勿执行。
-- 业务「仪表盘」菜单：与前端默认跳转 /business/dashboard 一致；执行一次即可。
-- 授权给「拥有通道管理(200)」的角色，与常见业务账号权限一致。

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component,
  query, route_name, is_frame, is_cache, menu_type, visible, status,
  perms, icon, create_by, create_time, remark
)
SELECT
  '仪表盘', 5, 0, 'dashboard', 'business/dashboard/index',
  '', '', 1, 0, 'C', '0', '0',
  'business:dashboard:list', 'dashboard', 'admin', NOW(), '业务概览'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sys_menu WHERE component = 'business/dashboard/index'
);

SET @dashboard_menu_id := (
  SELECT menu_id FROM sys_menu WHERE component = 'business/dashboard/index' LIMIT 1
);

INSERT INTO sys_role_menu (role_id, menu_id)
SELECT rm.role_id, @dashboard_menu_id
FROM sys_role_menu rm
WHERE rm.menu_id = 200
  AND @dashboard_menu_id IS NOT NULL
ON DUPLICATE KEY UPDATE role_id = VALUES(role_id);
