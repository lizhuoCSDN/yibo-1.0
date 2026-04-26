-- 移除「短信营销」下的「业务概览」菜单（原 business/dashboard/index；内容已迁至固定路由 /index）
-- 可重复执行：无对应菜单时各步影响 0 行。
SET NAMES utf8mb4;

SET @d := (
  SELECT menu_id FROM sys_menu
  WHERE path = 'dashboard' AND menu_type = 'C' AND component = 'business/dashboard/index'
  LIMIT 1
);

DELETE FROM sys_role_menu WHERE @d IS NOT NULL AND menu_id IN (
  SELECT menu_id FROM sys_menu WHERE parent_id = @d
);
DELETE FROM sys_menu WHERE @d IS NOT NULL AND parent_id = @d;

DELETE FROM sys_role_menu WHERE @d IS NOT NULL AND menu_id = @d;
DELETE FROM sys_menu WHERE @d IS NOT NULL AND menu_id = @d;

-- 短信营销下子项顺序（与 regroup 一致；若已用新版 regroup 可跳过）：发送页面(1)…(6)；统计页侧栏隐藏
SET @p_mk := (SELECT menu_id FROM sys_menu WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);
UPDATE sys_menu SET order_num = 1 WHERE @p_mk IS NOT NULL AND path = 'import'         AND parent_id = @p_mk;
UPDATE sys_menu SET order_num = 2 WHERE @p_mk IS NOT NULL AND path = 'template'        AND parent_id = @p_mk;
UPDATE sys_menu SET order_num = 3 WHERE @p_mk IS NOT NULL AND path = 'userlink'        AND parent_id = @p_mk;
UPDATE sys_menu SET order_num = 4 WHERE @p_mk IS NOT NULL AND path = 'contact'        AND parent_id = @p_mk;
UPDATE sys_menu SET order_num = 5 WHERE @p_mk IS NOT NULL AND path = 'keyword'        AND parent_id = @p_mk;
UPDATE sys_menu SET order_num = 6 WHERE @p_mk IS NOT NULL AND path = 'contentReview'  AND parent_id = @p_mk;
UPDATE sys_menu SET visible = '1', order_num = 80 WHERE @p_mk IS NOT NULL AND path = 'statistics' AND parent_id = @p_mk;
UPDATE sys_menu SET visible = '1' WHERE path = 'statistics' AND menu_type = 'C' AND component = 'business/statistics/index';
UPDATE sys_menu SET remark = '发送页面/模板/链接管理/数据仓库/统计' WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0;

SELECT 'remove_dashboard_business_menu: done' AS result;
