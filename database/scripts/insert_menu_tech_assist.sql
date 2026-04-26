-- 技术协助：C 菜单（若尚无）+ F 按钮权限；父级为「账户管理」需与 regroup_sms_sidebar_menus.sql 同跑或本脚本内 UPDATE
SET NAMES utf8mb4;

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '技术协助', 0, 4, 'techAssist', 'business/techAssist/index', 1, 0, 'C', '0', '0', 'business:techAssist:list', 'question', 'admin', NOW(), '通道路由协助单'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index');

SET @tid := (SELECT menu_id FROM sys_menu WHERE path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index' LIMIT 1);

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '提交协助', @tid, 1, '#', '', 1, 0, 'F', '0', '0', 'business:techAssist:add', '#', 'admin', NOW()
FROM DUAL WHERE @tid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @tid AND perms = 'business:techAssist:add');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '处理L1', @tid, 2, '#', '', 1, 0, 'F', '0', '0', 'business:techAssist:handle1', '#', 'admin', NOW()
FROM DUAL WHERE @tid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @tid AND perms = 'business:techAssist:handle1');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '处理L2', @tid, 3, '#', '', 1, 0, 'F', '0', '0', 'business:techAssist:handle2', '#', 'admin', NOW()
FROM DUAL WHERE @tid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @tid AND perms = 'business:techAssist:handle2');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '处理L3', @tid, 4, '#', '', 1, 0, 'F', '0', '0', 'business:techAssist:handle3', '#', 'admin', NOW()
FROM DUAL WHERE @tid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @tid AND perms = 'business:techAssist:handle3');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time)
SELECT '处理L4', @tid, 5, '#', '', 1, 0, 'F', '0', '0', 'business:techAssist:handle4', '#', 'admin', NOW()
FROM DUAL WHERE @tid IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @tid AND perms = 'business:techAssist:handle4');

SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
UPDATE sys_menu SET parent_id = @p_acct, order_num = 5, update_time = NOW()
WHERE @p_acct IS NOT NULL AND path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id) SELECT 1, menu_id FROM sys_menu WHERE path = 'techAssist' OR parent_id = @tid;

SELECT 'insert_menu_tech_assist: done' AS result;
