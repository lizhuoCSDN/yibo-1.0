-- 通讯录分组（与 SmsContactGroupMapper / domain 一致）
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS sms_contact_group (
  id             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  group_name     VARCHAR(128) NOT NULL COMMENT '分组名称',
  user_id        BIGINT                DEFAULT NULL COMMENT '归属用户',
  contact_count  INT          NOT NULL DEFAULT 0 COMMENT '联系人数量',
  create_by      VARCHAR(64)           DEFAULT NULL,
  create_time    DATETIME              DEFAULT NULL,
  update_by      VARCHAR(64)           DEFAULT NULL,
  update_time    DATETIME              DEFAULT NULL,
  del_flag       CHAR(1)      NOT NULL DEFAULT '0' COMMENT '0存在 2删除',
  PRIMARY KEY (id),
  KEY idx_scg_user (user_id),
  KEY idx_scg_del (del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信通讯录分组';
