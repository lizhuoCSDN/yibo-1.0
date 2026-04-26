-- Fix garbled menu_name (????) for outbound tree — use UTF-8 bytes (works regardless of client encoding).
SET NAMES utf8mb4;
-- 接口外放（接+口+外+放）
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('E68EA5E58FA3E5A496E694BE') USING utf8mb4) WHERE path = 'outbound' AND menu_type = 'M' LIMIT 1;
-- API外放
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('415049E5A496E694BE') USING utf8mb4) WHERE path = 'apikey' AND menu_type = 'C' LIMIT 1;
-- SMPP外放
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('534D5050E5A496E694BE') USING utf8mb4) WHERE path = 'smppAccount' AND menu_type = 'C' LIMIT 1;
