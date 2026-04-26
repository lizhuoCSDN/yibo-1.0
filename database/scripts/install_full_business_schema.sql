-- 一次补全 ruoyi-business 所需表结构（IF NOT EXISTS / 条件 ALTER，可重复执行）
SET NAMES utf8mb4;
SET @db = DATABASE();

-- ========== sms_channel 扩展字段（E2E / 线路国家等）==========
SELECT COUNT(*) INTO @cc FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_channel' AND COLUMN_NAME = 'country';
SET @sql = IF(@cc = 0,
  'ALTER TABLE sms_channel ADD COLUMN country varchar(128) NULL DEFAULT NULL COMMENT ''country or region'' AFTER channel_code',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ========== 关键词、余额、任务、记录 ==========
CREATE TABLE IF NOT EXISTS sms_keyword (
  id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'id',
  keyword      VARCHAR(128) NOT NULL,
  category     VARCHAR(32)   DEFAULT NULL,
  match_type   CHAR(1)       DEFAULT '0',
  status       CHAR(1)       DEFAULT '0',
  remark       VARCHAR(500)  DEFAULT NULL,
  create_by    VARCHAR(64)   DEFAULT NULL,
  create_time  DATETIME      DEFAULT NULL,
  update_by    VARCHAR(64)   DEFAULT NULL,
  update_time  DATETIME      DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_sms_keyword_kw (keyword(64)),
  KEY idx_sms_keyword_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SMS keyword';

CREATE TABLE IF NOT EXISTS sms_user_balance (
  id          BIGINT         NOT NULL AUTO_INCREMENT,
  user_id     BIGINT         NOT NULL,
  parent_id   BIGINT         DEFAULT NULL,
  balance     DECIMAL(20,2)  NOT NULL DEFAULT 0,
  total_used  DECIMAL(20,2)  DEFAULT 0,
  status      CHAR(1)        DEFAULT '0',
  create_by   VARCHAR(64)    DEFAULT NULL,
  create_time DATETIME       DEFAULT NULL,
  update_by   VARCHAR(64)    DEFAULT NULL,
  update_time DATETIME       DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_sms_user_balance_uid (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户短信余额/用量';

CREATE TABLE IF NOT EXISTS sms_balance_log (
  id              BIGINT         NOT NULL AUTO_INCREMENT,
  user_id         BIGINT         NOT NULL,
  channel_id      BIGINT         DEFAULT NULL,
  change_type     VARCHAR(32)    DEFAULT NULL,
  change_count    INT            DEFAULT NULL,
  amount            DECIMAL(20,4)  DEFAULT NULL COMMENT '变动金额(元)，与条数/change_count并存',
  balance_before  DECIMAL(20,2)  DEFAULT NULL,
  balance_after   DECIMAL(20,2)  DEFAULT NULL,
  create_time     DATETIME       DEFAULT NULL,
  create_by       VARCHAR(64)    DEFAULT NULL,
  remark          VARCHAR(500)   DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_sbl_user (user_id),
  KEY idx_sbl_ch (channel_id),
  KEY idx_sbl_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='余额/条数消费明细';

CREATE TABLE IF NOT EXISTS sms_send_task (
  id            BIGINT        NOT NULL AUTO_INCREMENT,
  task_no       VARCHAR(64)   NOT NULL,
  user_id       BIGINT        DEFAULT NULL,
  user_name     VARCHAR(30)   DEFAULT NULL,
  review_owner_id BIGINT      DEFAULT NULL COMMENT '待处理审核的账户ID',
  channel_id    BIGINT        DEFAULT NULL,
  channel_name  VARCHAR(100)  DEFAULT NULL,
  sms_content   TEXT,
  original_url  VARCHAR(2000) DEFAULT NULL,
  domain_ids    VARCHAR(500)  DEFAULT NULL,
  template_id   BIGINT        DEFAULT NULL,
  phone_source  VARCHAR(32)   DEFAULT NULL,
  total_count   INT           DEFAULT 0,
  success_count INT           DEFAULT 0,
  fail_count    INT           DEFAULT 0,
  pending_count INT           DEFAULT 0,
  status        CHAR(1)       DEFAULT '0',
  timing_type   VARCHAR(20)   DEFAULT NULL,
  timing_time   DATETIME      DEFAULT NULL,
  start_time    DATETIME      DEFAULT NULL,
  finish_time   DATETIME      DEFAULT NULL,
  bill_unit_price DECIMAL(20,4) DEFAULT NULL COMMENT '外放对客单条短信售价(元/条，用于发信后扣费)',
  create_by     VARCHAR(64)   DEFAULT NULL,
  create_time   DATETIME      DEFAULT NULL,
  update_by     VARCHAR(64)   DEFAULT NULL,
  update_time   DATETIME      DEFAULT NULL,
  remark        VARCHAR(500)  DEFAULT NULL,
  del_flag      CHAR(1)       NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_sst_un (user_id),
  KEY idx_sst_st (status),
  KEY idx_sst_tn (task_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信发送任务';

CREATE TABLE IF NOT EXISTS sms_send_record (
  id           BIGINT         NOT NULL AUTO_INCREMENT,
  task_id      BIGINT         DEFAULT NULL,
  task_no      VARCHAR(64)    DEFAULT NULL,
  user_id      BIGINT         DEFAULT NULL,
  channel_id   BIGINT         DEFAULT NULL,
  phone_number VARCHAR(32)    NOT NULL,
  status       CHAR(1)        DEFAULT '0',
  short_url    VARCHAR(500)   DEFAULT NULL,
  domain_name  VARCHAR(200)   DEFAULT NULL,
  sms_content  TEXT,
  send_time    DATETIME       DEFAULT NULL,
  create_by    VARCHAR(64)    DEFAULT NULL,
  create_time  DATETIME       DEFAULT NULL,
  update_by    VARCHAR(64)    DEFAULT NULL,
  update_time  DATETIME       DEFAULT NULL,
  remark       VARCHAR(500)   DEFAULT NULL,
  del_flag     CHAR(1)        NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_ssr_task (task_id),
  KEY idx_ssr_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信发送明细';

-- sync_sms 增量列（与 sync_sms_schema_e2e 一致逻辑）
SET @c = 0;
SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'template_id';
SET @sql = IF(@c = 0, 'ALTER TABLE sms_send_task ADD COLUMN template_id BIGINT NULL AFTER domain_ids', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'phone_source';
SET @sql = IF(@c = 0, 'ALTER TABLE sms_send_task ADD COLUMN phone_source VARCHAR(32) NULL AFTER template_id', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'del_flag';
SET @sql = IF(@c = 0, 'ALTER TABLE sms_send_record ADD COLUMN del_flag CHAR(1) DEFAULT ''0''', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_record' AND COLUMN_NAME = 'send_time';
SET @sql = IF(@c = 0, 'ALTER TABLE sms_send_record ADD COLUMN send_time DATETIME NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

UPDATE sms_send_record SET del_flag = '0' WHERE del_flag IS NULL OR del_flag = '';

-- ========== 通讯录、模板（若此前未建）==========
CREATE TABLE IF NOT EXISTS sms_template (
  id               BIGINT       NOT NULL AUTO_INCREMENT,
  template_name    VARCHAR(200) NOT NULL,
  template_content TEXT,
  user_id          BIGINT                DEFAULT NULL,
  ref_task_id      BIGINT                DEFAULT NULL,
  status           CHAR(1)      NOT NULL DEFAULT '0',
  create_by        VARCHAR(64)           DEFAULT NULL,
  create_time      DATETIME              DEFAULT NULL,
  update_by        VARCHAR(64)           DEFAULT NULL,
  update_time      DATETIME              DEFAULT NULL,
  remark           VARCHAR(500)          DEFAULT NULL,
  del_flag         CHAR(1)      NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_st_user (user_id),
  KEY idx_st_df (del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信模板';

CREATE TABLE IF NOT EXISTS sms_contact_group (
  id             BIGINT       NOT NULL AUTO_INCREMENT,
  group_name     VARCHAR(128) NOT NULL,
  user_id        BIGINT                DEFAULT NULL,
  contact_count  INT          NOT NULL DEFAULT 0,
  create_by      VARCHAR(64)           DEFAULT NULL,
  create_time    DATETIME              DEFAULT NULL,
  update_by      VARCHAR(64)           DEFAULT NULL,
  update_time    DATETIME              DEFAULT NULL,
  del_flag       CHAR(1)      NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_scg_u (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通讯录分组';

CREATE TABLE IF NOT EXISTS sms_contact (
  id            BIGINT         NOT NULL AUTO_INCREMENT,
  group_id      BIGINT         NOT NULL,
  phone_number  VARCHAR(32)    NOT NULL,
  contact_name  VARCHAR(100)   DEFAULT NULL,
  user_id       BIGINT         DEFAULT NULL,
  create_by     VARCHAR(64)    DEFAULT NULL,
  create_time   DATETIME       DEFAULT NULL,
  update_by     VARCHAR(64)    DEFAULT NULL,
  update_time   DATETIME       DEFAULT NULL,
  remark        VARCHAR(500)   DEFAULT NULL,
  del_flag      CHAR(1)        NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_sct_g (group_id),
  KEY idx_sct_u (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通讯录联系人';

-- ========== 通道分配、健康、API Key ==========
CREATE TABLE IF NOT EXISTS sms_channel_health (
  id BIGINT NOT NULL AUTO_INCREMENT,
  channel_id BIGINT NOT NULL,
  success_count BIGINT NOT NULL DEFAULT 0,
  fail_count BIGINT NOT NULL DEFAULT 0,
  total_count BIGINT NOT NULL DEFAULT 0,
  success_rate DECIMAL(10,2) DEFAULT NULL,
  avg_response_ms INT DEFAULT NULL,
  circuit_state CHAR(1) NOT NULL DEFAULT '0',
  circuit_open_time DATETIME DEFAULT NULL,
  weight INT NOT NULL DEFAULT 100,
  priority INT NOT NULL DEFAULT 0,
  window_start DATETIME DEFAULT NULL,
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ch_ch (channel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通道健康';

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
  KEY idx_suc_u (user_id),
  KEY idx_suc_c (channel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户-通道';

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
  UNIQUE KEY uk_ak_app (app_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='API Key';

-- ========== SMPP、链上钱包 ==========
CREATE TABLE IF NOT EXISTS `sms_smpp_account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `system_id` varchar(32) NOT NULL,
  `password` varchar(128) NOT NULL,
  `rate_limit` int DEFAULT '100',
  `sale_price` decimal(20,4) DEFAULT NULL COMMENT '售价(元/条)',
  `channel_id` bigint DEFAULT NULL,
  `status` char(1) DEFAULT '0',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(64) DEFAULT '',
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(64) DEFAULT '',
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_smpp_system_id` (`system_id`),
  KEY `idx_smpp_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SMPP 账号';

CREATE TABLE IF NOT EXISTS user_link_click_log (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_link_id` bigint NOT NULL,
  `click_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_link_id` (`user_link_id`),
  KEY `idx_click_time` (`click_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS wallet_usdt_sync_state (
  usdt_address VARCHAR(128) NOT NULL,
  last_sync_at DATETIME NOT NULL,
  row_count INT NOT NULL DEFAULT 0,
  update_time DATETIME DEFAULT NULL,
  PRIMARY KEY (usdt_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS wallet_usdt_bind (
  id            BIGINT         NOT NULL AUTO_INCREMENT,
  account_code  VARCHAR(64)    NOT NULL,
  usdt_address  VARCHAR(128)   NOT NULL,
  chain_type    VARCHAR(16)    NOT NULL DEFAULT 'TRC20',
  bind_role     VARCHAR(32)    NOT NULL DEFAULT 'CUSTOMER' COMMENT 'INTERNAL/COMPETITOR/CUSTOMER',
  remark        VARCHAR(500)   DEFAULT NULL,
  create_by     VARCHAR(64)    DEFAULT NULL,
  create_time   DATETIME       DEFAULT NULL,
  update_by     VARCHAR(64)    DEFAULT NULL,
  update_time   DATETIME       DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_wba (account_code),
  UNIQUE KEY uk_wbad (usdt_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS wallet_usdt_tx (
  id           BIGINT         NOT NULL AUTO_INCREMENT,
  tx_hash      VARCHAR(128)   NOT NULL,
  from_address VARCHAR(128)  NOT NULL,
  to_address   VARCHAR(128)  NOT NULL,
  amount       DECIMAL(36,18) NOT NULL,
  tx_time      DATETIME      DEFAULT NULL,
  remark       VARCHAR(500)  DEFAULT NULL,
  create_by    VARCHAR(64)   DEFAULT NULL,
  create_time  DATETIME      DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_wtxh (tx_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT 'install_full_business_schema: done' AS result;
