-- 从库中彻底移除：用户/角色/菜单/部门/岗位 五类管理侧栏（若依 100-104 及子按钮，含 F）。
-- 说明：若依超管侧栏为 selectMenuTreeAll() 读全表 sys_menu，与 sys_role_menu 无关，必须删行而非仅去角色。
-- 判重同时兼容老库 menu_id=100..104 与任意自增 id（在「系统管理」M 下 path 为 user/role/menu/dept/post）。
-- 可重复执行。
SET NAMES utf8mb4;
SET SESSION cte_max_recursion_depth = 20;

CREATE TEMPORARY TABLE tmp_remove_system_mgmt (menu_id BIGINT PRIMARY KEY);
INSERT INTO tmp_remove_system_mgmt (menu_id)
WITH RECURSIVE t AS (
  SELECT menu_id FROM sys_menu
  WHERE menu_id IN (100, 101, 102, 103, 104)
  UNION
  SELECT m.menu_id
  FROM sys_menu m
  INNER JOIN sys_menu p ON p.menu_id = m.parent_id
  WHERE p.path = 'system' AND p.menu_type = 'M' AND p.parent_id = 0
    AND m.path IN ('user', 'role', 'menu', 'dept', 'post') AND m.menu_type = 'C'
  UNION ALL
  SELECT m.menu_id FROM sys_menu m INNER JOIN t ON m.parent_id = t.menu_id
)
SELECT menu_id FROM t;

SET @rm_count := (SELECT COUNT(*) FROM tmp_remove_system_mgmt);

DELETE r FROM sys_role_menu r
INNER JOIN tmp_remove_system_mgmt t ON r.menu_id = t.menu_id;

DELETE m FROM sys_menu m
INNER JOIN tmp_remove_system_mgmt t ON m.menu_id = t.menu_id;

DROP TEMPORARY TABLE IF EXISTS tmp_remove_system_mgmt;

SELECT CONCAT('remove_five_system_mgmt_menus: removed ', @rm_count, ' menu row(s)') AS result;
