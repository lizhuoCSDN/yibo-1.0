-- 技术协助单（与内容审核类似：多级通过 / 升级）
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS sms_tech_assist (
  id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  page_code VARCHAR(32) NOT NULL COMMENT '来源页面: channel, channelRouter, apikey, smpp',
  page_label VARCHAR(64) DEFAULT NULL COMMENT '来源页面名称',
  ref_id BIGINT DEFAULT NULL COMMENT '关联主键(可选)',
  ref_summary VARCHAR(512) DEFAULT NULL COMMENT '关联摘要(通道名/路由行等)',
  question TEXT NOT NULL COMMENT '问题描述',
  status CHAR(1) NOT NULL DEFAULT '0' COMMENT '0 待处理 1 已通过',
  pending_level TINYINT NOT NULL DEFAULT 1 COMMENT '当前待处理层级 1-4',
  last_action_remark VARCHAR(500) DEFAULT NULL COMMENT '最后操作备注',
  del_flag CHAR(1) NOT NULL DEFAULT '0' COMMENT '0 存在 2 删除',
  create_by VARCHAR(64) DEFAULT NULL,
  create_time DATETIME DEFAULT NULL,
  update_by VARCHAR(64) DEFAULT NULL,
  update_time DATETIME DEFAULT NULL,
  finish_by VARCHAR(64) DEFAULT NULL,
  finish_time DATETIME DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_ta_status (status, pending_level),
  KEY idx_ta_create (create_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='通道路由-技术协助单';

SELECT 'create_sms_tech_assist: done' AS result;
