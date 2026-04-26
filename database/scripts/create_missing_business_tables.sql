-- Tables for ???????? / ???????? (run once on yibo)
SET NAMES utf8mb4;

SET @db = DATABASE();
SELECT COUNT(*) INTO @cc FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_channel' AND COLUMN_NAME = 'country';
SET @sql = IF(@cc = 0,
  'ALTER TABLE sms_channel ADD COLUMN country varchar(128) NULL DEFAULT NULL COMMENT ''country or region'' AFTER channel_code',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS sms_channel_health (
  id BIGINT NOT NULL AUTO_INCREMENT,
  channel_id BIGINT NOT NULL COMMENT 'sms_channel.id',
  success_count BIGINT NOT NULL DEFAULT 0,
  fail_count BIGINT NOT NULL DEFAULT 0,
  total_count BIGINT NOT NULL DEFAULT 0,
  success_rate DECIMAL(10,2) DEFAULT NULL,
  avg_response_ms INT DEFAULT NULL,
  circuit_state CHAR(1) NOT NULL DEFAULT '0' COMMENT '0 normal 1 open 2 half',
  circuit_open_time DATETIME DEFAULT NULL,
  weight INT NOT NULL DEFAULT 100,
  priority INT NOT NULL DEFAULT 0,
  window_start DATETIME DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_channel_health_ch (channel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='??????????????';

CREATE TABLE IF NOT EXISTS sms_user_channel (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  channel_id BIGINT NOT NULL,
  price DECIMAL(12,4) DEFAULT NULL,
  allot_count BIGINT DEFAULT NULL,
  used_count BIGINT DEFAULT 0,
  enabled CHAR(1) DEFAULT '1',
  create_by VARCHAR(64) DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_by VARCHAR(64) DEFAULT NULL,
  update_time DATETIME DEFAULT NULL,
  remark VARCHAR(500) DEFAULT NULL,
  success_rate_min DECIMAL(5,2) DEFAULT NULL,
  success_rate_max DECIMAL(5,2) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_suc_uid (user_id),
  KEY idx_suc_cid (channel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='user channel allocation';

CREATE TABLE IF NOT EXISTS sms_api_key (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  app_id VARCHAR(64) NOT NULL,
  app_secret VARCHAR(128) NOT NULL,
  app_name VARCHAR(100) DEFAULT NULL,
  rate_limit INT DEFAULT 300,
  sale_price DECIMAL(20,4) DEFAULT NULL COMMENT '售价(元/条)',
  status CHAR(1) DEFAULT '0',
  api_open CHAR(1) DEFAULT '1',
  smpp_open CHAR(1) DEFAULT '1',
  whitelist_ips VARCHAR(500) DEFAULT NULL,
  create_by VARCHAR(64) DEFAULT NULL,
  create_time DATETIME DEFAULT NULL,
  update_by VARCHAR(64) DEFAULT NULL,
  update_time DATETIME DEFAULT NULL,
  remark VARCHAR(500) DEFAULT NULL,
  del_flag CHAR(1) DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY uk_sms_api_key_app (app_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='HTTP API outbound keys';
