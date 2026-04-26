-- 【已过期】旧版：敏感词/内容审核挂通道路由。当前请用 regroup_sms_sidebar_menus.sql 或 add_account_management_menu_group.sql
-- 保留脚本仅作历史参考；重复执行可能与「账户管理」结构冲突。
SET NAMES utf8mb4;

SET @p_ops := (SELECT menu_id FROM sys_menu WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

UPDATE sys_menu
SET parent_id = @p_ops, order_num = 5, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND path = 'keyword'
  AND menu_type = 'C'
  AND component = 'business/keyword/index';

UPDATE sys_menu
SET parent_id = @p_ops, order_num = 6, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND path = 'contentReview'
  AND menu_type = 'C'
  AND component = 'business/contentReview/index';

UPDATE sys_menu
SET order_num = 7, update_time = NOW()
WHERE @p_ops IS NOT NULL
  AND path = 'outbound'
  AND menu_type = 'M'
  AND parent_id = @p_ops;

UPDATE sys_menu SET remark = '发送页面/模板/链接管理/数据仓库/统计' WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET remark = '通道/路由/新户/分配/敏感词页/内容审核/外放' WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

-- 有子权限的角色补挂通道路由父菜单（与 regroup 一致）
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, p.menu_id
FROM sys_menu p
JOIN sys_menu c ON c.parent_id = p.menu_id
JOIN sys_role_menu r ON r.menu_id = c.menu_id
WHERE p.path = 'smsOps' AND p.parent_id = 0 AND p.menu_type = 'M';

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE path = 'smsOps' AND parent_id = 0 AND menu_type = 'M';

SELECT 'relocate_keyword_content_review_smsops: done' AS result;
