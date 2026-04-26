USE yibo;

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT 1, menu_id FROM sys_menu WHERE component = 'business/dashboard/index' AND menu_type = 'C' LIMIT 1;

SET @dbname = DATABASE();
SET @preparedStatement = (SELECT IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @dbname AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'user_level') > 0,
  'SELECT 1',
  'ALTER TABLE sys_user ADD COLUMN user_level CHAR(1) DEFAULT ''3'' COMMENT ''user level 1/2/3'''
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE sys_user SET user_level = '1' WHERE user_id = 1 AND (user_level IS NULL OR user_level = '');

SELECT 'role_menu_dashboard' AS chk, COUNT(*) AS cnt FROM sys_role_menu WHERE role_id = 1 AND menu_id IN (SELECT menu_id FROM sys_menu WHERE component = 'business/dashboard/index');
SELECT 'user_level_exists' AS chk, COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'user_level';
