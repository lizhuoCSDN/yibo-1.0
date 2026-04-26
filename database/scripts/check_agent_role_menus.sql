SELECT rm.menu_id, m.path, m.menu_name, m.parent_id
FROM sys_role_menu rm
JOIN sys_menu m ON m.menu_id = rm.menu_id
WHERE rm.role_id = 5
ORDER BY m.parent_id, m.order_num;
