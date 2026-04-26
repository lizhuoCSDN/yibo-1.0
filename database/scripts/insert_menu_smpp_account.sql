-- SMPP 菜单挂在「接口外放」(outbound M) 下。在 outbound 目录菜单已存在时执行。

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP外放', (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1), 2, 'smppAccount', 'business/smppAccount/index', 'C', '0', '0', 'business:smppAccount:list', 'message', 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP查询', menu_id, 1, '#', '', 'F', '0', '0', 'business:smppAccount:query', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP新增', menu_id, 2, '#', '', 'F', '0', '0', 'business:smppAccount:add', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP修改', menu_id, 3, '#', '', 'F', '0', '0', 'business:smppAccount:edit', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP删除', menu_id, 4, '#', '', 'F', '0', '0', 'business:smppAccount:remove', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;
