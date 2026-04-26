-- 侧栏：财务统计( analysis ) 在系统管理( system ) 上方
-- 与 regroup_sms_sidebar_menus.sql 第 4) 节一致，可重复执行
SET NAMES utf8mb4;

UPDATE sys_menu SET order_num = 30 WHERE path = 'analysis' AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 31 WHERE path = 'system'  AND menu_type = 'M' AND parent_id = 0;

SELECT 'reorder_system_below_finance: done' AS result;
