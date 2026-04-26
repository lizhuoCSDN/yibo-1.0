-- 【已废弃】见 add_business_dashboard_menu.sql 说明；业务概览现为 /index。
-- 为管理员角色(role_id=1)绑定「仪表盘」菜单，使 getRouters 包含 /business/dashboard（与侧边栏一致）。
-- 执行前请确认 sys_menu 中已存在 component = business/dashboard/index 的菜单（见 menu_insert.sql）。

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE component = 'business/dashboard/index' AND menu_type = 'C' LIMIT 1;
