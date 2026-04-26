-- 侧栏：接口外放=国际化目录；子项 link=API、message=短信，避免与父级同图标
SET NAMES utf8mb4;
UPDATE sys_menu SET icon = 'international' WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1;
UPDATE sys_menu SET icon = 'link'      WHERE path = 'apikey'   AND menu_type = 'C' LIMIT 1;
UPDATE sys_menu SET icon = 'message'   WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;
