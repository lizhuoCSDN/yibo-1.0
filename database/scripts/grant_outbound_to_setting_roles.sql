-- Grant outbound/apikey/smpp + buttons to every role that already has 账户通道 (path=setting)
-- 或其子菜单，或任一与业务侧栏相关的菜单（顶级 business 路径、外放/财务子树等）。
SET NAMES utf8mb4;

SET @outbound_id := (SELECT menu_id FROM sys_menu WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1);

-- 满足以下任一条的 role_id：曾拥有「账户通道」或业务侧栏任一项
-- （与 install_full_business_menus 中 role_id=2 的覆盖范围一致思路）
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @outbound_id
FROM sys_role_menu r
WHERE @outbound_id IS NOT NULL
  AND r.role_id IN (
    SELECT DISTINCT role_id FROM sys_role_menu WHERE menu_id IN (
      SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = (SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0 LIMIT 1)
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN (
        'import', 'template', 'contact', 'keyword', 'channel', 'newUser',
        'channelRouter', 'userlink', 'statistics', 'contentReview',
        'outbound', 'analysis'
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT m.menu_id FROM sys_menu m
        WHERE m.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
        )
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT c.menu_id FROM sys_menu c
        WHERE c.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path = 'analysis'
        )
      )
    )
  );

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, m.menu_id
FROM sys_role_menu r
CROSS JOIN sys_menu m
WHERE @outbound_id IS NOT NULL
  AND m.parent_id = @outbound_id
  AND r.role_id IN (
    SELECT DISTINCT role_id FROM sys_role_menu WHERE menu_id IN (
      SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = (SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0 LIMIT 1)
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN (
        'import', 'template', 'contact', 'keyword', 'channel', 'newUser',
        'channelRouter', 'userlink', 'statistics', 'contentReview',
        'outbound', 'analysis'
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT m2.menu_id FROM sys_menu m2
        WHERE m2.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
        )
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT c.menu_id FROM sys_menu c
        WHERE c.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path = 'analysis'
        )
      )
    )
  );

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, m.menu_id
FROM sys_role_menu r
CROSS JOIN sys_menu m
WHERE @outbound_id IS NOT NULL
  AND m.parent_id IN (SELECT menu_id FROM sys_menu WHERE parent_id = @outbound_id)
  AND r.role_id IN (
    SELECT DISTINCT role_id FROM sys_role_menu WHERE menu_id IN (
      SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = (SELECT menu_id FROM sys_menu WHERE path = 'setting' AND menu_type = 'M' AND parent_id = 0 LIMIT 1)
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN (
        'import', 'template', 'contact', 'keyword', 'channel', 'newUser',
        'channelRouter', 'userlink', 'statistics', 'contentReview',
        'outbound', 'analysis'
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT m2.menu_id FROM sys_menu m2
        WHERE m2.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path IN ('outbound', 'analysis')
        )
      )
      UNION ALL
      SELECT menu_id FROM sys_menu WHERE parent_id IN (
        SELECT c.menu_id FROM sys_menu c
        WHERE c.parent_id IN (
          SELECT menu_id FROM sys_menu WHERE parent_id = 0 AND path = 'analysis'
        )
      )
    )
  );
