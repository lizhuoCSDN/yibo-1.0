-- Sensitive words for SMS content audit (sms_keyword)
-- Charset: utf8mb4

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
