-- 将原「业务管理」path=business 下的所有直接子菜单提升到与「系统管理」同级（parent_id=0），并删除 business 根菜单。
-- 接口外放(outbound)、财务(analysis) 等带子菜单的目录一并提升；子项仍挂在原父级下。
-- 可重复执行：若已无 business 根菜单则跳过。
SET NAMES utf8mb4;

SET @biz := (SELECT menu_id FROM sys_menu WHERE path = 'business' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 保留原顺序：新 order_num = 100 + 原 order_num（避免与现有顶级菜单 1~4 冲突，可在 菜单管理 中再拖顺序）
UPDATE sys_menu m
INNER JOIN (
  SELECT menu_id, order_num AS old_o FROM sys_menu WHERE @biz IS NOT NULL AND parent_id = @biz
) t ON m.menu_id = t.menu_id
SET m.parent_id = 0, m.order_num = 100 + t.old_o
WHERE @biz IS NOT NULL;

DELETE FROM sys_role_menu WHERE @biz IS NOT NULL AND menu_id = @biz;
DELETE FROM sys_menu WHERE @biz IS NOT NULL AND menu_id = @biz;

-- 如 outbound 因历史原因仍挂在已删的 business 下，请手工检查；正常情况已随上一步 parent_id 一并改为 0
