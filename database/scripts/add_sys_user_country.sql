-- Same as ensure_sys_user_country.sql (kept for older docs / one-liner users).
-- Prefer: ensure_sys_user_country.sql

SET @db := DATABASE();
SET @exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db
    AND TABLE_NAME = 'sys_user'
    AND COLUMN_NAME = 'country'
);

SET @sql := IF(
  @exists = 0,
  'ALTER TABLE sys_user ADD COLUMN country VARCHAR(128) NULL DEFAULT NULL COMMENT ''Country/region'' AFTER phonenumber',
  'SELECT ''skip: sys_user.country already exists'' AS msg'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
