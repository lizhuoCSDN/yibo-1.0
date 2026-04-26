-- 账户线路可提交量预警：计划发送前若干小时内，若本账户在该线路的剩余可提交数低于阈值，则写通知公告
CREATE TABLE IF NOT EXISTS sms_user_channel_alert (
  id                  BIGINT         NOT NULL AUTO_INCREMENT,
  user_id             BIGINT         NOT NULL,
  channel_id          BIGINT         NOT NULL,
  min_threshold       BIGINT         NOT NULL DEFAULT 100000 COMMENT '剩余可提交条数低于此值时触发',
  lead_hours          INT            NOT NULL DEFAULT 6     COMMENT '计划发送整点前多少小时开始提醒',
  planned_send_hour   TINYINT        NOT NULL DEFAULT 22   COMMENT '计划发送的本地小时 0-23',
  enabled             CHAR(1)        NOT NULL DEFAULT '1',
  last_notice_id      BIGINT         NULL   COMMENT '关联 sys_notice 以便更新同一条',
  create_by           VARCHAR(64)    NULL,
  create_time         DATETIME       NULL,
  update_by           VARCHAR(64)    NULL,
  update_time         DATETIME       NULL,
  del_flag            CHAR(1)        NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  KEY idx_sms_uc_alert_user (user_id, del_flag),
  KEY idx_sms_uc_alert_ch (channel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户线路可提交量预警';
