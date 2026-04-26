-- 将「操作日志 / 登录日志」提升到与「通知公告」同级（挂在「系统管理」下），并删除父级「日志管理」
-- 若依约定：通知公告 order≈8；两日志为 order=9、10；在线用户 order=11
-- 兼容：仅 path='log'、仅 menu_name='日志管理'、或 500/501 已挂在非 system 的 M 下
SET NAMES utf8mb4;

SET @sys := (SELECT menu_id FROM sys_menu WHERE path = 'system' AND menu_type = 'M' AND parent_id = 0 LIMIT 1);

-- 1) 定位 C 菜单：优先在「系统管理 → 日志管理(log 或 名称)」下；否则已在系统管理下；再否则 500/501 挂在日志目录下
SET @op := COALESCE(
  (SELECT m.menu_id FROM sys_menu m
   INNER JOIN sys_menu p ON p.menu_id = m.parent_id
   WHERE m.path = 'operlog' AND m.menu_type = 'C' AND p.parent_id = @sys AND p.menu_type = 'M'
   AND (p.path = 'log' OR TRIM(p.menu_name) = '日志管理') LIMIT 1),
  (SELECT menu_id FROM sys_menu WHERE path = 'operlog' AND menu_type = 'C' AND parent_id = @sys LIMIT 1),
  (SELECT m.menu_id FROM sys_menu m
   INNER JOIN sys_menu p ON p.menu_id = m.parent_id
   WHERE m.menu_id = 500 AND m.menu_type = 'C' AND p.parent_id = @sys AND p.menu_type = 'M'
   AND (p.path = 'log' OR TRIM(p.menu_name) = '日志管理') LIMIT 1)
);

SET @li := COALESCE(
  (SELECT m.menu_id FROM sys_menu m
   INNER JOIN sys_menu p ON p.menu_id = m.parent_id
   WHERE m.path = 'logininfor' AND m.menu_type = 'C' AND p.parent_id = @sys AND p.menu_type = 'M'
   AND (p.path = 'log' OR TRIM(p.menu_name) = '日志管理') LIMIT 1),
  (SELECT menu_id FROM sys_menu WHERE path = 'logininfor' AND menu_type = 'C' AND parent_id = @sys LIMIT 1),
  (SELECT m.menu_id FROM sys_menu m
   INNER JOIN sys_menu p ON p.menu_id = m.parent_id
   WHERE m.menu_id = 501 AND m.menu_type = 'C' AND p.parent_id = @sys AND p.menu_type = 'M'
   AND (p.path = 'log' OR TRIM(p.menu_name) = '日志管理') LIMIT 1)
);

-- 2) 待删除的「日志管理」M：必须是 系统管理 下 path=log 或 名称匹配，且为 @op / @li 的父级之一
SET @logm := (
  SELECT p.menu_id FROM sys_menu p
  WHERE p.parent_id = @sys AND p.menu_type = 'M'
  AND (p.path = 'log' OR TRIM(p.menu_name) = '日志管理')
  AND (
    p.menu_id = (SELECT x.parent_id FROM sys_menu x WHERE x.menu_id = @op LIMIT 1)
    OR p.menu_id = (SELECT y.parent_id FROM sys_menu y WHERE y.menu_id = @li LIMIT 1)
  )
  LIMIT 1
);

-- 3) 拥有「日志管理」目录的角色，补挂两子菜单（若尚未有）
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @op FROM sys_role_menu r WHERE @logm IS NOT NULL AND @op IS NOT NULL AND r.menu_id = @logm;

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @li FROM sys_role_menu r WHERE @logm IS NOT NULL AND @li IS NOT NULL AND r.menu_id = @logm;

-- 4) 挂到系统管理
UPDATE sys_menu SET parent_id = @sys, order_num = 9, update_time = NOW()
WHERE @sys IS NOT NULL AND @op IS NOT NULL AND menu_id = @op;

UPDATE sys_menu SET parent_id = @sys, order_num = 10, update_time = NOW()
WHERE @sys IS NOT NULL AND @li IS NOT NULL AND menu_id = @li;

UPDATE sys_menu SET order_num = 11, update_time = NOW()
WHERE @sys IS NOT NULL AND path = 'online' AND menu_type = 'C' AND parent_id = @sys;

-- 5) 删父级 M 行及角色关联
DELETE FROM sys_role_menu WHERE @logm IS NOT NULL AND menu_id = @logm;
DELETE FROM sys_menu WHERE @logm IS NOT NULL AND menu_id = @logm;

-- 6) 其余空壳：系统管理 下 仍名「日志管理」或 path=log 的 M 且无子节点（防漏删）
-- MySQL 禁止 DELETE 目标表在子查询中直接自引用，用派生表包一层
DELETE r FROM sys_role_menu r
WHERE r.menu_id IN (
  SELECT id FROM (
    SELECT m.menu_id AS id FROM sys_menu m
    WHERE m.parent_id = @sys AND m.menu_type = 'M'
      AND (m.path = 'log' OR TRIM(m.menu_name) = '日志管理')
      AND NOT EXISTS (SELECT 1 FROM sys_menu c WHERE c.parent_id = m.menu_id)
  ) t
);

DELETE FROM sys_menu WHERE menu_id IN (
  SELECT id FROM (
    SELECT m.menu_id AS id FROM sys_menu m
    WHERE m.parent_id = @sys AND m.menu_type = 'M'
      AND (m.path = 'log' OR TRIM(m.menu_name) = '日志管理')
      AND NOT EXISTS (SELECT 1 FROM sys_menu c WHERE c.parent_id = m.menu_id)
  ) t2
);

SELECT 'flatten_log_menu_under_system: done' AS result;
