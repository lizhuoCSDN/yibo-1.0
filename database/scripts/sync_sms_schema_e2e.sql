-- Align yibo DB with current MyBatis mappers (idempotent where possible).
-- Run: mysql -u root -p -D yibo < sync_sms_schema_e2e.sql

CREATE TABLE IF NOT EXISTS sms_keyword (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'id',
  keyword      VARCHAR(128) NOT NULL COMMENT 'keyword text',
  category     VARCHAR(32)           DEFAULT NULL COMMENT 'category',
  match_type   CHAR(1)               DEFAULT '0' COMMENT '0 contains 1 exact',
  status       CHAR(1)               DEFAULT '0' COMMENT '0 normal 1 disabled',
  remark       VARCHAR(500)          DEFAULT NULL,
  create_by    VARCHAR(64)           DEFAULT NULL,
  create_time  DATETIME              DEFAULT NULL,
  update_by    VARCHAR(64)           DEFAULT NULL,
  update_time  DATETIME              DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_sms_keyword_kw (keyword(64)),
  KEY idx_sms_keyword_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SMS sensitive keywords';

SET @db = DATABASE();

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'template_id';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_task ADD COLUMN template_id BIGINT NULL COMMENT ''��������ģ��ID'' AFTER domain_ids',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'phone_source';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_task ADD COLUMN phone_source VARCHAR(32) NULL COMMENT ''������Դ'' AFTER template_id',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'del_flag';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN del_flag CHAR(1) DEFAULT ''0'' COMMENT ''ɾ����־''',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'send_time';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN send_time DATETIME NULL COMMENT ''����ʱ��''',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'create_by';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN create_by VARCHAR(64) NULL',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'update_by';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN update_by VARCHAR(64) NULL',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'update_time';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN update_time DATETIME NULL',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'remark';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_record ADD COLUMN remark VARCHAR(500) NULL',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

UPDATE sms_send_record SET del_flag = '0' WHERE del_flag IS NULL OR del_flag = '';
