-- 短信模板表（与 SmsTemplateMapper / domain 一致）
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS sms_template (
  id               BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  template_name    VARCHAR(200) NOT NULL COMMENT '模板名称',
  template_content TEXT                  DEFAULT NULL COMMENT '模板内容',
  user_id          BIGINT                DEFAULT NULL COMMENT '归属用户',
  ref_task_id      BIGINT                DEFAULT NULL COMMENT '关联发送任务',
  status           CHAR(1)      NOT NULL DEFAULT '0' COMMENT '0正常 1停用',
  create_by        VARCHAR(64)           DEFAULT NULL,
  create_time      DATETIME              DEFAULT NULL,
  update_by        VARCHAR(64)           DEFAULT NULL,
  update_time      DATETIME              DEFAULT NULL,
  remark           VARCHAR(500)          DEFAULT NULL,
  del_flag         CHAR(1)      NOT NULL DEFAULT '0' COMMENT '0存在 2删除',
  PRIMARY KEY (id),
  KEY idx_sms_template_user (user_id),
  KEY idx_sms_template_status (status),
  KEY idx_sms_template_del (del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信模板';
