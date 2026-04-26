-- 将原先平铺的短信业务菜单收拢为三级结构（可重复执行）
-- 顶级：短信营销(smsMk)、账户管理(accountMgmt)、通道路由(smsOps)；「点击统计」侧栏已隐藏(visible=1)。
-- 账户管理：新户管理、敏感词页、内容审核、通知公告、技术协助（线路分配已并入新户内，无独立侧栏项）；通道路由：通道、智能路由、API外放、SMPP外放。
-- 技术协助(techAssist) 挂在「账户管理」(accountMgmt) 下。路由：/accountMgmt/techAssist
-- 其它路由：/import -> /smsMk/import；新户等 -> /accountMgmt/...；/smsOps/apikey、/smsOps/smppAccount
SET NAMES utf8mb4;

-- 1) 业务顶级目录（M + Layout）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '短信营销', 0, 20, 'smsMk', 'Layout', 1, 0, 'M', '0', '0', '', 'message', 'admin', NOW(), '数据仓库/发送页面/模板/链接管理/统计'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0);

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '账户管理', 0, 21, 'accountMgmt', 'Layout', 1, 0, 'M', '0', '0', '', 'peoples', 'admin', NOW(), '新户/敏感词/内容审核/通知公告/技术协助'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0);

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '技术协助', 0, 4, 'techAssist', 'business/techAssist/index', 1, 0, 'C', '0', '0', 'business:techAssist:list', 'question', 'admin', NOW(), '通道路由协助单'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '通道路由', 0, 22, 'smsOps', 'Layout', 1, 0, 'M', '0', '0', '', 'guide', 'admin', NOW(), '通道/智能路由/API外放/SMPP'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0);

SET @p_mk   := (SELECT menu_id FROM sys_menu WHERE path = 'smsMk'   AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
SET @p_acct := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
SET @p_ops  := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps'  AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 1a) 已存在的老数据若误写为 ParentView，统一改为 Layout
UPDATE sys_menu SET component = 'Layout'
WHERE path IN ('smsMk', 'accountMgmt', 'smsOps', 'analysis') AND menu_type = 'M' AND parent_id = 0 AND component = 'ParentView';

-- 1c) 名称与备注
UPDATE sys_menu SET menu_name = '通道路由'
WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

UPDATE sys_menu SET menu_name = '账户管理', remark = '新户/敏感词/内容审核/通知公告/技术协助'
WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0;

UPDATE sys_menu SET remark = '发送页面/模板/链接管理/数据仓库/统计' WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET remark = '通道/智能路由/API外放/SMPP' WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

-- 1d) 「子账户」更名为「新户管理」
UPDATE sys_menu SET menu_name = '新户管理' WHERE path = 'newUser' AND menu_type = 'C';

-- 1e) 「敏感词」更名为「敏感词页」
UPDATE sys_menu SET menu_name = '敏感词页' WHERE path = 'keyword' AND menu_type = 'C' AND component = 'business/keyword/index';

-- 1f) 「导入管理」→「发送页面」
UPDATE sys_menu SET menu_name = '发送页面' WHERE path = 'import' AND menu_type = 'C' AND component = 'business/import/index';

-- 通讯录显示为「数据仓库」
UPDATE sys_menu SET menu_name = '数据仓库', icon = 'table', remark = '分组与号码'
WHERE path = 'contact' AND menu_type = 'C' AND component = 'business/contact/index';

-- 2) 短信营销：发送页面 -> 模板 -> 链接管理 -> 数据仓库（path=statistics 侧栏隐藏）
UPDATE sys_menu SET parent_id = @p_mk, order_num = 1 WHERE path = 'import'         AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 2 WHERE path = 'template'       AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 3 WHERE path = 'userlink'        AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 4 WHERE path = 'contact'        AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, visible = '1', order_num = 80 WHERE path = 'statistics'     AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET visible = '1' WHERE path = 'statistics' AND menu_type = 'C' AND component = 'business/statistics/index';

-- 3) 账户管理：新户 -> 敏感词页 -> 内容审核 -> 通知公告 -> 技术协助
UPDATE sys_menu SET parent_id = @p_acct, order_num = 1 WHERE path = 'newUser'        AND menu_type = 'C' AND @p_acct IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_acct, order_num = 2 WHERE path = 'keyword'        AND menu_type = 'C' AND component = 'business/keyword/index' AND @p_acct IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_acct, order_num = 3 WHERE path = 'contentReview'   AND menu_type = 'C' AND @p_acct IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_acct, order_num = 4, update_time = NOW()
WHERE path = 'notice' AND menu_type = 'C' AND component = 'system/notice/index' AND @p_acct IS NOT NULL;

-- 3b) 技术协助：账户管理 子菜单
UPDATE sys_menu SET parent_id = @p_acct, order_num = 5, update_time = NOW()
WHERE path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index' AND @p_acct IS NOT NULL;

-- 4) 通道路由：通道 -> 智能路由 -> API外放 -> SMPP外放（不再使用「接口外放」M）
UPDATE sys_menu SET parent_id = @p_ops, order_num = 1 WHERE path = 'channel'        AND menu_type = 'C' AND @p_ops IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_ops, order_num = 2 WHERE path = 'channelRouter'  AND menu_type = 'C' AND @p_ops IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_ops, order_num = 3 WHERE path = 'apikey'         AND menu_type = 'C' AND component = 'business/apikey/index' AND @p_ops IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_ops, order_num = 4 WHERE path = 'smppAccount'   AND menu_type = 'C' AND component = 'business/smppAccount/index' AND @p_ops IS NOT NULL;

SET @outbound_rm := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);
DELETE FROM sys_role_menu WHERE @outbound_rm IS NOT NULL AND menu_id = @outbound_rm;
DELETE FROM sys_menu WHERE @outbound_rm IS NOT NULL AND menu_id = @outbound_rm;

-- 5) 顶级顺序（系统管理在财务统计之后）
UPDATE sys_menu SET order_num = 10 WHERE path = 'smsMk'         AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 11 WHERE path = 'accountMgmt'   AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 12 WHERE path = 'smsOps'        AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 30 WHERE path = 'analysis'       AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 31 WHERE path = 'system'         AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 40 WHERE path = 'tool'           AND menu_type = 'M' AND parent_id = 0;

-- 6) 角色：拥有子菜单的自动补挂父目录
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path IN ('smsMk', 'accountMgmt', 'smsOps', 'system') AND p.parent_id = 0 AND p.menu_type = 'M';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE path IN ('smsMk', 'accountMgmt', 'smsOps', 'system') AND parent_id = 0;

SELECT 'regroup_sms_sidebar_menus: done' AS result;
