-- 已上线库：移除「发送素材 / 号码库」菜单，将「通讯录」改为「数据仓库」并挂到「短信营销」下（与 regroup 一致）
-- 会删除表 sms_phone_warehouse 及菜单 warehouse、smsData；需保留数据请先备份
SET NAMES utf8mb4;

SET @p_mk := (SELECT menu_id FROM sys_menu WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 1) 数据仓库（regroup 当前顺序中 order_num=4；「点击统计」已隐藏）
UPDATE sys_menu
SET parent_id = COALESCE(@p_mk, parent_id), order_num = 4, menu_name = '数据仓库', icon = 'table', remark = '分组与号码'
WHERE path = 'contact' AND menu_type = 'C' AND component = 'business/contact/index' AND @p_mk IS NOT NULL;

UPDATE sys_menu SET order_num = 1 WHERE path = 'import'   AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET order_num = 2 WHERE path = 'template' AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET order_num = 3 WHERE path = 'userlink' AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET order_num = 4 WHERE path = 'contact'  AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET order_num = 5 WHERE path = 'keyword'  AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET order_num = 6 WHERE path = 'contentReview' AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET visible = '1', order_num = 80 WHERE path = 'statistics' AND parent_id = @p_mk AND menu_type = 'C' AND @p_mk IS NOT NULL;
UPDATE sys_menu SET visible = '1' WHERE path = 'statistics' AND menu_type = 'C' AND component = 'business/statistics/index';

-- 2) 号码库菜单
DELETE FROM sys_role_menu WHERE menu_id IN (SELECT m.menu_id FROM (SELECT menu_id FROM sys_menu WHERE path = 'warehouse' AND menu_type = 'C') m);
DELETE FROM sys_menu WHERE path = 'warehouse' AND menu_type = 'C';

-- 3) 发送素材（顶级 M）及其下残留授权
DELETE FROM sys_role_menu WHERE menu_id IN (SELECT m.menu_id FROM (SELECT menu_id FROM sys_menu WHERE path = 'smsData' AND menu_type = 'M' AND parent_id = 0) m);
DELETE FROM sys_menu WHERE path = 'smsData' AND menu_type = 'M' AND parent_id = 0;

-- 4) 表（可选，与后端删除配套）
DROP TABLE IF EXISTS sms_phone_warehouse;

UPDATE sys_menu SET order_num = 10 WHERE path = 'smsMk' AND menu_type = 'M' AND parent_id = 0;
UPDATE sys_menu SET order_num = 11 WHERE path = 'smsOps' AND menu_type = 'M' AND parent_id = 0;

SELECT 'migrate_remove_smsData_warehouse: done' AS result;
