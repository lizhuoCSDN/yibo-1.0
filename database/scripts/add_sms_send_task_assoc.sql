-- 发送任务关联：模板管理、号码来源（执行一次即可，重复执行若报「重复列」可忽略）
USE yibo;

ALTER TABLE sms_send_task ADD COLUMN template_id BIGINT NULL COMMENT '关联短信模板ID' AFTER domain_ids;
ALTER TABLE sms_send_task ADD COLUMN phone_source VARCHAR(32) NULL COMMENT '号码来源 manual|file|warehouse|contact_group' AFTER template_id;
