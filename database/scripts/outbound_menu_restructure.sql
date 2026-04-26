-- 菜单：业务(5) -> 接口外放(M outbound) -> API / SMPP 子菜单
-- Run once on existing DB (utf8mb4).

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '接口外放', 5, 9, 'outbound', 'ParentView', 'M', '0', '0', '', 'international', 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M');

SET @outbound_id := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);

UPDATE sys_menu SET parent_id = @outbound_id, menu_name = 'API外放', order_num = 1, icon = 'link'
WHERE path = 'apikey' AND menu_type = 'C';

UPDATE sys_menu SET parent_id = @outbound_id, menu_name = 'SMPP外放', order_num = 2, icon = 'message'
WHERE path = 'smppAccount' AND menu_type = 'C';
