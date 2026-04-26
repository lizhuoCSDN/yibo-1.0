-- 在「系统管理」同级（parent_id=0）下补全与前端 business/* 页面对应的菜单（可重复执行）
-- 重要：regroup 会把下列菜单挂到短信营销/通道路由下，故「是否已存在」不能再用 parent_id=0，须按 path+menu_type 全库判重，否则会重复插入。
SET NAMES utf8mb4;

-- 规范旧数据 path；兼容仍挂在 业务 根下或已提升到顶级两种情况
-- 注意：MySQL 8 多表 UPDATE 不可带 LIMIT，故 JOIN 处省略 LIMIT
UPDATE sys_menu SET path = 'import'   WHERE path = '/import'   AND parent_id = 0 LIMIT 1;
UPDATE sys_menu m INNER JOIN sys_menu b ON b.path = 'business' AND b.menu_type = 'M' AND b.parent_id = 0
  SET m.path = 'import'   WHERE m.path = '/import'   AND m.parent_id = b.menu_id;
UPDATE sys_menu SET path = 'userlink' WHERE path = '/userlink' AND parent_id = 0 LIMIT 1;
UPDATE sys_menu m INNER JOIN sys_menu b ON b.path = 'business' AND b.menu_type = 'M' AND b.parent_id = 0
  SET m.path = 'userlink' WHERE m.path = '/userlink' AND m.parent_id = b.menu_id;
UPDATE sys_menu SET path = 'statistcis' WHERE path = '/statistcis' AND parent_id = 0 LIMIT 1;
UPDATE sys_menu m INNER JOIN sys_menu b ON b.path = 'business' AND b.menu_type = 'M' AND b.parent_id = 0
  SET m.path = 'statistcis' WHERE m.path = '/statistcis' AND m.parent_id = b.menu_id;
UPDATE sys_menu SET path = 'channel'  WHERE path = '/business' AND component LIKE 'business/channel/index%' AND parent_id = 0 LIMIT 1;
UPDATE sys_menu m INNER JOIN sys_menu b ON b.path = 'business' AND b.menu_type = 'M' AND b.parent_id = 0
  SET m.path = 'channel'  WHERE m.path = '/business' AND m.component LIKE 'business/channel/index%' AND m.parent_id = b.menu_id;

-- 业务概览为前端固定路由 /index，不再插入 dashboard 菜单

-- 发送页面（导入/任务；regroup 后挂在短信营销 smsMk 下）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '发送页面', 0, 1, 'import', 'business/import/index', 1, 0, 'C', '0', '0', 'business:sendTask:list', 'guide', 'admin', NOW(), '创建任务/导入号码'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'import' AND menu_type = 'C' AND component = 'business/import/index');

-- 模板 / 数据仓库 / 敏感词页、内容审核（子目录归属以 regroup_sms_sidebar_menus.sql 为准；敏感词与内容审核在「账户管理」下）
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '短信模板', 0, 2, 'template', 'business/template/index', 1, 0, 'C', '0', '0', 'business:template:list', 'form', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'template' AND menu_type = 'C' AND component = 'business/template/index');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '数据仓库', 0, 3, 'contact', 'business/contact/index', 1, 0, 'C', '0', '0', 'business:contact:list', 'table', 'admin', NOW(), '分组与号码'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'contact' AND menu_type = 'C' AND component = 'business/contact/index');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '敏感词页', 0, 4, 'keyword', 'business/keyword/index', 1, 0, 'C', '0', '0', 'business:keyword:list', 'search', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'keyword' AND menu_type = 'C' AND component = 'business/keyword/index');

-- 通道 / 新户管理
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '通道管理', 0, 5, 'channel', 'business/channel/index', 1, 0, 'C', '0', '0', 'business:channel:list', 'message', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'channel' AND menu_type = 'C' AND component LIKE 'business/channel/index%');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '新户管理', 0, 7, 'newUser', 'business/newUser/index', 1, 0, 'C', '0', '0', 'business:newUser:list', 'user', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'newUser' AND menu_type = 'C' AND component = 'business/newUser/index');

-- 智能路由 + 分配
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '智能路由', 0, 6, 'channelRouter', 'business/channelRouter/index', 1, 0, 'C', '0', '0', 'business:channelRouter:list', 'skill', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'channelRouter' AND menu_type = 'C' AND component = 'business/channelRouter/index');

-- 线路分配（独立页）已取消侧栏；分配能力在新户管理-账户概览中，不插入 sys_menu

-- 链接管理（path=userlink）/ 统计 / 内容审核
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '链接管理', 0, 9, 'userlink', 'business/userlink/index', 1, 0, 'C', '0', '0', 'business:userlink:list', 'link', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'userlink' AND menu_type = 'C' AND component LIKE 'business/userlink%');

-- 历史侧栏名：短链、用户链接、用户链接管理 等 → 统一为「链接管理」
UPDATE sys_menu SET menu_name = '链接管理', update_time = NOW()
WHERE path = 'userlink' AND menu_type = 'C' AND component LIKE 'business/userlink%';

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '统计分析', 0, 10, 'statistics', 'business/statistics/index', 1, 0, 'C', '1', '0', 'business:statistics:list', 'chart', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE menu_type = 'C' AND (path = 'statistics' OR path = 'statistcis') AND component = 'business/statistics/index');

-- 如仍为旧 path statistcis，改名指到新页
UPDATE sys_menu SET path = 'statistics', component = 'business/statistics/index' WHERE path = 'statistcis' AND menu_type = 'C';

-- 不展示侧栏「点击统计」（若库内已有为显示状态则一并改）
UPDATE sys_menu SET visible = '1' WHERE path = 'statistics' AND menu_type = 'C' AND component = 'business/statistics/index';

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '内容审核', 0, 11, 'contentReview', 'business/contentReview/index', 1, 0, 'C', '0', '0', 'business:contentReview:list', 'edit', 'admin', NOW(), ''
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'contentReview' AND menu_type = 'C' AND component = 'business/contentReview/index');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '技术协助', 0, 12, 'techAssist', 'business/techAssist/index', 1, 0, 'C', '0', '0', 'business:techAssist:list', 'question', 'admin', NOW(), '通道路由协助单'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index');

-- 财务子目录 analysis + 子菜单
INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '财务统计', 0, 13, 'analysis', 'Layout', 1, 0, 'M', '0', '0', '', 'money', 'admin', NOW(), '余额/利润/链上'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_menu WHERE path = 'analysis' AND menu_type = 'M');

SET @an := COALESCE(
  (SELECT menu_id FROM sys_menu WHERE path = 'analysis' AND menu_type = 'M' AND parent_id = 0 LIMIT 1),
  (SELECT menu_id FROM sys_menu WHERE path = 'analysis' AND menu_type = 'M' LIMIT 1)
);

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '消费明细', @an, 1, 'financeBalanceLog', 'business/finance/balanceLog', 1, 0, 'C', '0', '0', 'business:finance:list', 'list', 'admin', NOW(), ''
FROM DUAL
WHERE @an IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @an AND path = 'financeBalanceLog');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '利润统计', @an, 2, 'financeProfit', 'business/finance/profit', 1, 0, 'C', '0', '0', 'business:finance:profit', 'chart', 'admin', NOW(), ''
FROM DUAL
WHERE @an IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @an AND path = 'financeProfit');

INSERT INTO sys_menu (menu_name, parent_id, order_num, path, component, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
SELECT '钱包分析', @an, 3, 'walletAnalysis', 'business/finance/walletAnalysis', 1, 0, 'C', '0', '0', 'business:wallet:list', 'money', 'admin', NOW(), 'USDT 链上'
FROM DUAL
WHERE @an IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM sys_menu WHERE parent_id = @an AND path = 'walletAnalysis');

-- 子角色（role_id=2）补挂本脚本涉及的顶级/二级/部分三级 business 菜单
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 2, m.menu_id FROM sys_menu m
WHERE
  (m.parent_id = 0 AND m.path IN (
    'import', 'template', 'contact', 'keyword', 'channel', 'newUser',
    'channelRouter', 'userlink', 'statistics', 'contentReview',
    'smsOps', 'analysis'
  ))
  OR (m.path = 'techAssist' AND m.component = 'business/techAssist/index' AND m.menu_type = 'C')
  OR m.parent_id IN (SELECT sm.menu_id FROM sys_menu sm WHERE sm.parent_id = 0 AND sm.path IN ('smsOps', 'analysis', 'system', 'accountMgmt'))
  OR m.parent_id IN (
    SELECT c.menu_id FROM sys_menu c
    WHERE c.parent_id IN (SELECT sm.menu_id FROM sys_menu sm WHERE sm.parent_id = 0 AND sm.path IN ('smsOps', 'analysis'))
  )
  OR m.parent_id IN (
    SELECT c2.menu_id FROM sys_menu c2
    WHERE c2.parent_id IN (
      SELECT c.menu_id FROM sys_menu c
      WHERE c.parent_id IN (SELECT sm.menu_id FROM sys_menu sm WHERE sm.parent_id = 0 AND sm.path = 'analysis')
    )
  );

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 2, m.menu_id FROM sys_menu m WHERE m.parent_id = @an;

-- 若已存在「账户管理」顶级，将技术协助挂入其下（与 regroup 一致；无 accountMgmt 时本段不生效）
SET @p_acct_if := (SELECT menu_id FROM sys_menu WHERE path = 'accountMgmt' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
UPDATE sys_menu SET parent_id = @p_acct_if, order_num = 5, update_time = NOW()
WHERE @p_acct_if IS NOT NULL AND path = 'techAssist' AND menu_type = 'C' AND component = 'business/techAssist/index';

-- API外放/SMPP 菜单由 regroup 挂到 smsOps；历史库可跑 repair_outbound_menu.sql 建 C 型菜单后再跑 flatten_outbound_to_smsops.sql
SELECT 'install_full_business_menus: done' AS result;
