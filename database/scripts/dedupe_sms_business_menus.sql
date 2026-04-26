-- 去重：install_full 曾用 parent_id=0 判断，regroup 后子菜单已挂到 smsMk/smsOps，再跑 install 会重复插入同 path 的 C 菜单，侧栏会显示多个「发送页面」等。
-- 对下列 path 的 C 类菜单，保留最小 menu_id 一条，角色权限合并到该条后删除重复行（含其下 F 子按钮）。
-- 可重复执行；无重复时 tmp 表为空，后续语句影响 0 行。
SET NAMES utf8mb4;

DROP TEMPORARY TABLE IF EXISTS tmp_menu_dedup;
CREATE TEMPORARY TABLE tmp_menu_dedup (
  old_id BIGINT NOT NULL,
  keep_id BIGINT NOT NULL,
  PRIMARY KEY (old_id),
  KEY (keep_id)
);

INSERT INTO tmp_menu_dedup (old_id, keep_id)
SELECT s.menu_id, k.keep_id
FROM sys_menu s
INNER JOIN (
  SELECT path, menu_type, MIN(menu_id) AS keep_id
  FROM sys_menu
  WHERE menu_type = 'C'
    AND path IN (
      'import', 'template', 'contact', 'keyword', 'channel', 'newUser',
      'channelRouter', 'userlink', 'statistics', 'contentReview'
    )
  GROUP BY path, menu_type
  HAVING COUNT(*) > 1
) k ON s.path = k.path AND s.menu_type = k.menu_type AND s.menu_id > k.keep_id;

-- 子按钮挂在重复 C 上时先删（避免外键/孤儿）
DELETE f FROM sys_menu f
INNER JOIN tmp_menu_dedup t ON f.parent_id = t.old_id;

-- 角色改挂到 keep_id
INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT r.role_id, t.keep_id
FROM sys_role_menu r
INNER JOIN tmp_menu_dedup t ON r.menu_id = t.old_id;

DELETE r FROM sys_role_menu r
INNER JOIN tmp_menu_dedup t ON r.menu_id = t.old_id;

DELETE s FROM sys_menu s
INNER JOIN tmp_menu_dedup t ON s.menu_id = t.old_id;

SELECT CONCAT('dedupe_sms_business_menus: removed ', COUNT(*), ' duplicate menu(s)') AS result
FROM tmp_menu_dedup;

DROP TEMPORARY TABLE IF EXISTS tmp_menu_dedup;
