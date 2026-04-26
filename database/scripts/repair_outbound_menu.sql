-- 接口外放（outbound）侧栏修复 —— 新结构见 flatten_outbound_to_smsops.sql（API外放、SMPP 与智能路由平级，无「接口外放」父级）。
-- 在业务库执行。可重复执行。
-- Fixes: wrong business root detection; grants all roles that already have any menu under 账户通道/业务.
SET NAMES utf8mb4;

-- 优先挂到「通道路由」smsOps（与 regroup_sms_sidebar_menus.sql 一致）；否则旧版 business 根；再否则从子菜单推断
SET @business_id := COALESCE(
  (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0 LIMIT 1),
  (SELECT menu_id FROM sys_menu WHERE path = 'business' AND menu_type = 'M' AND parent_id = 0 LIMIT 1),
  (SELECT parent_id FROM sys_menu WHERE path IN ('newUser', 'channel', 'channelRouter', 'import', 'userlink') AND menu_type = 'C' LIMIT 1)
);

UPDATE sys_menu SET parent_id = @business_id
WHERE path = 'outbound' AND menu_type = 'M' AND @business_id IS NOT NULL;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '接口外放', @business_id, 9, 'outbound', 'ParentView', 'M', '0', '0', '', 'international', 'admin', NOW()
FROM DUAL
WHERE @business_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M');

SET @outbound_id := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);

UPDATE sys_menu SET status = '0', visible = '0'
WHERE path IN ('outbound', 'apikey', 'smppAccount') AND @outbound_id IS NOT NULL;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'API外放', @outbound_id, 1, 'apikey', 'business/apikey/index', 'C', '0', '0', 'business:apikey:list', 'link', 'admin', NOW()
FROM DUAL
WHERE @outbound_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'apikey' AND menu_type = 'C');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP外放', @outbound_id, 2, 'smppAccount', 'business/smppAccount/index', 'C', '0', '0', 'business:smppAccount:list', 'message', 'admin', NOW()
FROM DUAL
WHERE @outbound_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C');

UPDATE sys_menu SET parent_id = @outbound_id, order_num = 1, menu_name = 'API外放', icon = 'link'
WHERE path = 'apikey' AND menu_type = 'C' AND @outbound_id IS NOT NULL;

UPDATE sys_menu SET parent_id = @outbound_id, order_num = 2, menu_name = 'SMPP外放', icon = 'message'
WHERE path = 'smppAccount' AND menu_type = 'C' AND @outbound_id IS NOT NULL;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP query', menu_id, 1, '#', '', 'F', '0', '0', 'business:smppAccount:query', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:smppAccount:query' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP add', menu_id, 2, '#', '', 'F', '0', '0', 'business:smppAccount:add', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:smppAccount:add' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP edit', menu_id, 3, '#', '', 'F', '0', '0', 'business:smppAccount:edit', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:smppAccount:edit' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'SMPP remove', menu_id, 4, '#', '', 'F', '0', '0', 'business:smppAccount:remove', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'smppAccount' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:smppAccount:remove' AND menu_type = 'F')
LIMIT 1;

-- API 外放按钮（与 SmsApiKeyController 一致）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'API query', menu_id, 1, '#', '', 'F', '0', '0', 'business:apikey:query', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'apikey' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:apikey:query' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'API add', menu_id, 2, '#', '', 'F', '0', '0', 'business:apikey:add', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'apikey' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:apikey:add' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'API edit', menu_id, 3, '#', '', 'F', '0', '0', 'business:apikey:edit', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'apikey' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:apikey:edit' AND menu_type = 'F')
LIMIT 1;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT 'API remove', menu_id, 4, '#', '', 'F', '0', '0', 'business:apikey:remove', '#', 'admin', NOW()
FROM sys_menu WHERE path = 'apikey' AND menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:apikey:remove' AND menu_type = 'F')
LIMIT 1;

SET @outbound_id := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);

-- Roles that can see the business root OR any direct child of it (same as 账户通道 column)
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @outbound_id
FROM sys_role_menu r
WHERE @outbound_id IS NOT NULL
  AND @business_id IS NOT NULL
  AND (
    r.menu_id = @business_id
    OR r.menu_id IN (SELECT menu_id FROM sys_menu WHERE parent_id = @business_id)
  );

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, m.menu_id
FROM sys_role_menu r
CROSS JOIN sys_menu m
WHERE @outbound_id IS NOT NULL
  AND @business_id IS NOT NULL
  AND m.parent_id = @outbound_id
  AND (
    r.menu_id = @business_id
    OR r.menu_id IN (SELECT menu_id FROM sys_menu WHERE parent_id = @business_id)
  );

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, m.menu_id
FROM sys_role_menu r
CROSS JOIN sys_menu m
WHERE @outbound_id IS NOT NULL
  AND @business_id IS NOT NULL
  AND m.parent_id IN (SELECT menu_id FROM sys_menu WHERE parent_id = @outbound_id)
  AND (
    r.menu_id = @business_id
    OR r.menu_id IN (SELECT menu_id FROM sys_menu WHERE parent_id = @business_id)
  );

-- Super-admin user_id=1 still uses all menus; keep role 1 in sync
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) SELECT 1, @outbound_id FROM DUAL WHERE @outbound_id IS NOT NULL;
INSERT IGNORE INTO sys_role_menu (role_id, menu_id) SELECT 1, menu_id FROM sys_menu WHERE parent_id = @outbound_id;
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, m.menu_id FROM sys_menu m INNER JOIN sys_menu p ON m.parent_id = p.menu_id WHERE p.parent_id = @outbound_id;
