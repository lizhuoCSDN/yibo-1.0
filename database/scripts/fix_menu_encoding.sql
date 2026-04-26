-- 修正菜单名称编码问题
-- 使用正确的UTF-8编码更新菜单名称

UPDATE sys_menu SET menu_name = _utf8mb4'线路分配' WHERE menu_id = 201;
UPDATE sys_menu SET menu_name = _utf8mb4'发送页面' WHERE menu_id = 203;

-- 验证更新
SELECT menu_id, menu_name, order_num FROM sys_menu WHERE menu_id IN (201, 203);
