-- Content audit: parent directory + two children
-- 1) 内容审核(M) 2) 敏感词的管理 -> business/keyword/index  3) 发送内容审核 -> business/keyword/audit
-- Run with: mysql --default-character-set=utf8mb4 ... < content_audit_submenus.sql
-- Idempotent: skips child inserts if path already exists under parent.

USE yibo;

SET @mid := (
  SELECT menu_id FROM sys_menu
  WHERE component = 'business/keyword/index' AND menu_type = 'C'
  LIMIT 1
);

SET @mid := IFNULL(
  @mid,
  (SELECT menu_id FROM sys_menu WHERE path = 'contentAudit' AND menu_type = 'M' LIMIT 1)
);

UPDATE sys_menu
SET menu_type = 'M',
    component = NULL,
    path = 'contentAudit',
    perms = ''
WHERE menu_id = @mid
  AND menu_type = 'C';

UPDATE sys_menu SET menu_name = '内容审核' WHERE menu_id = @mid;

SELECT @mid AS content_audit_parent_menu_id;

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark
)
SELECT
  '敏感词的管理', @mid, 1, 'keywordManage', 'business/keyword/index', '', '',
  1, 0, 'C', '0', '0', 'business:keyword:list', 'list', 'admin', NOW(), '敏感词列表'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sys_menu WHERE parent_id = @mid AND path = 'keywordManage'
);

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark
)
SELECT
  '发送内容审核', @mid, 2, 'sendContentAudit', 'business/keyword/audit', '', '',
  1, 0, 'C', '0', '0', 'business:keyword:list', 'edit', 'admin', NOW(), '短信内容敏感词检测'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sys_menu WHERE parent_id = @mid AND path = 'sendContentAudit'
);

SET @kid := (SELECT menu_id FROM sys_menu WHERE parent_id = @mid AND path = 'keywordManage' LIMIT 1);
UPDATE sys_menu
SET parent_id = @kid
WHERE menu_type = 'F'
  AND parent_id = @mid
  AND @kid IS NOT NULL;

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE parent_id = @mid AND path IN ('keywordManage', 'sendContentAudit');
