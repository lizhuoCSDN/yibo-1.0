-- Run these in MySQL to see why outbound does not show (paste results if still stuck).
SET NAMES utf8mb4;

SELECT 'business root' AS step, menu_id, menu_name, path, parent_id, status, visible, menu_type
FROM sys_menu
WHERE parent_id = 0 OR path = 'business'
ORDER BY menu_id;

SELECT 'outbound rows' AS step, menu_id, menu_name, path, parent_id, status, visible, menu_type
FROM sys_menu
WHERE path IN ('outbound', 'apikey', 'smppAccount');

SELECT 'role_menu for outbound tree' AS step, rm.role_id, r.role_name, rm.menu_id, m.path
FROM sys_role_menu rm
LEFT JOIN sys_menu m ON m.menu_id = rm.menu_id
LEFT JOIN sys_role r ON r.role_id = rm.role_id
WHERE rm.menu_id IN (
  SELECT menu_id FROM sys_menu WHERE path IN ('outbound', 'apikey', 'smppAccount')
  UNION
  SELECT menu_id FROM sys_menu WHERE parent_id IN (
    SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M'
  )
)
ORDER BY rm.role_id, rm.menu_id;
