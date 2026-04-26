-- 子菜单名；图标以 polish_outbound_sidebar_icons.sql 为准（link / message）
SET NAMES utf8mb4;
UPDATE sys_menu SET menu_name = 'API外放', icon = 'link'
WHERE path = 'apikey' AND menu_type = 'C' LIMIT 1;
UPDATE sys_menu SET menu_name = 'SMPP外放', icon = 'message'
WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;
