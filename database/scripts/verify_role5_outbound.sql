SELECT rm.role_id, r.role_key, rm.menu_id, m.path
FROM sys_role_menu rm
JOIN sys_role r ON r.role_id = rm.role_id
JOIN sys_menu m ON m.menu_id = rm.menu_id
WHERE m.path IN ('outbound','apikey','smppAccount')
ORDER BY rm.role_id, rm.menu_id;
