-- Granular SMS keyword permissions (F buttons under ���дʵĹ��� keywordManage).
-- Run after content_audit_submenus.sql / create_sms_keyword.sql. Charset utf8mb4.

USE yibo;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '�ؼ��ʲ�ѯ', p.menu_id, 1, '#', '', '', '',
  1, 0, 'F', '0', '0', 'business:keyword:query', '#', 'admin', NOW(), ''
FROM sys_menu p
WHERE p.path = 'keywordManage' AND p.menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:keyword:query' AND menu_type = 'F');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '�ؼ�������', p.menu_id, 2, '#', '', '', '',
  1, 0, 'F', '0', '0', 'business:keyword:add', '#', 'admin', NOW(), ''
FROM sys_menu p
WHERE p.path = 'keywordManage' AND p.menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:keyword:add' AND menu_type = 'F');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '�ؼ����޸�', p.menu_id, 3, '#', '', '', '',
  1, 0, 'F', '0', '0', 'business:keyword:edit', '#', 'admin', NOW(), ''
FROM sys_menu p
WHERE p.path = 'keywordManage' AND p.menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:keyword:edit' AND menu_type = 'F');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '�ؼ���ɾ��', p.menu_id, 4, '#', '', '', '',
  1, 0, 'F', '0', '0', 'business:keyword:remove', '#', 'admin', NOW(), ''
FROM sys_menu p
WHERE p.path = 'keywordManage' AND p.menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:keyword:remove' AND menu_type = 'F');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '�ؼ���ˢ�»���', p.menu_id, 5, '#', '', '', '',
  1, 0, 'F', '0', '0', 'business:keyword:reload', '#', 'admin', NOW(), ''
FROM sys_menu p
WHERE p.path = 'keywordManage' AND p.menu_type = 'C'
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE perms = 'business:keyword:reload' AND menu_type = 'F');

-- Grant new button menus to every role that already has the keywordManage page menu
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, f.menu_id
FROM sys_role_menu r
JOIN sys_menu km ON km.menu_id = r.menu_id AND km.path = 'keywordManage' AND km.menu_type = 'C'
JOIN sys_menu f ON f.parent_id = km.menu_id AND f.menu_type = 'F'
  AND f.perms IN (
    'business:keyword:query',
    'business:keyword:add',
    'business:keyword:edit',
    'business:keyword:remove',
    'business:keyword:reload'
  );

-- Super admin (role_id=1): ensure all keyword F menus
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu
WHERE menu_type = 'F'
  AND perms IN (
    'business:keyword:query',
    'business:keyword:add',
    'business:keyword:edit',
    'business:keyword:remove',
    'business:keyword:reload'
  );
