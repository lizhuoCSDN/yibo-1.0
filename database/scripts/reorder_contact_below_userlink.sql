-- =============================================================================
-- 交换侧栏「链接管理」与「数据仓库」的顺序（只动这两项的 order_num）
-- =============================================================================
-- 为什么界面没变？
--   1) 必须在「正在使用的数据库」里执行本脚本（只保存文件无效）
--   2) 执行后请重新登录，或 Ctrl+F5 强刷
--   3) 若仍不变，检查是否连错库、或 Redis 里缓存了菜单（重启后端 / 清 Redis）
--
-- 执行前可先跑下面诊断（可选）：
--   SELECT menu_id, menu_name, path, component, parent_id, order_num
--   FROM sys_menu
--   WHERE menu_name IN ('链接管理','数据仓库') OR path IN ('userlink','contact');
-- =============================================================================

-- 父菜单：优先用「链接管理」所在行；否则用「数据仓库」；再否则用 path/component
SET @parent := COALESCE(
  (SELECT parent_id FROM sys_menu WHERE path = 'userlink' AND menu_type = 'C' LIMIT 1),
  (SELECT parent_id FROM sys_menu WHERE menu_name IN ('链接管理', '用户链接', '短链', '用户链接管理') AND menu_type = 'C' LIMIT 1),
  (SELECT parent_id FROM sys_menu WHERE (path = 'contact' OR component = 'business/contact/index') AND menu_type = 'C' LIMIT 1),
  (SELECT parent_id FROM sys_menu WHERE menu_name = '数据仓库' AND menu_type = 'C' LIMIT 1),
  5
);

SET @a := (
  SELECT order_num FROM sys_menu
  WHERE parent_id = @parent AND menu_type = 'C'
    AND (path = 'userlink' OR menu_name IN ('链接管理', '用户链接', '短链', '用户链接管理'))
  LIMIT 1
);
SET @b := (
  SELECT order_num FROM sys_menu
  WHERE parent_id = @parent AND menu_type = 'C'
    AND (path = 'contact' OR component = 'business/contact/index' OR menu_name = '数据仓库')
  LIMIT 1
);

-- 若任一为 NULL，说明 WHERE 仍对不上你库里的数据，请用上面的诊断 SQL 改条件
SELECT @parent AS resolved_parent_id, @a AS order_userlink_before, @b AS order_contact_before;

UPDATE sys_menu SET order_num = 99998
WHERE parent_id = @parent AND menu_type = 'C'
  AND (path = 'userlink' OR menu_name IN ('链接管理', '用户链接', '短链', '用户链接管理'));

UPDATE sys_menu SET order_num = @a
WHERE parent_id = @parent AND menu_type = 'C'
  AND (path = 'contact' OR component = 'business/contact/index' OR menu_name = '数据仓库');

UPDATE sys_menu SET order_num = @b
WHERE parent_id = @parent AND menu_type = 'C'
  AND (path = 'userlink' OR menu_name IN ('链接管理', '用户链接', '短链', '用户链接管理'));
