-- 侧栏隐藏「点击统计」(path=statistics)，并压紧同组顺序（与 regroup 第 2 段一致，可单跑）。
SET NAMES utf8mb4;

SET @p_mk := (SELECT menu_id FROM sys_menu WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

UPDATE sys_menu SET parent_id = @p_mk, order_num = 1 WHERE path = 'import'         AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 2 WHERE path = 'template'      AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 3 WHERE path = 'userlink'      AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 4 WHERE path = 'contact'        AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 5 WHERE path = 'keyword'        AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, order_num = 6 WHERE path = 'contentReview'  AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET parent_id = @p_mk, visible = '1', order_num = 80 WHERE path = 'statistics'     AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET visible = '1' WHERE path = 'statistics' AND menu_type = 'C' AND component = 'business/statistics/index';

UPDATE sys_menu SET remark = '发送页面/模板/链接管理/数据仓库/统计' WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0;

SELECT 'reorder_warehouse_below_statistics: done' AS result;
