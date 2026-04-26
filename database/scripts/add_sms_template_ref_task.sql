-- sms_template: optional link to send task (template ref)
-- Run once on your DB: mysql -u... -p your_db < add_sms_template_ref_task.sql
-- If column already exists, skip or comment out this file.

ALTER TABLE sms_template
  ADD COLUMN ref_task_id BIGINT(20) NULL DEFAULT NULL COMMENT 'ref send task id' AFTER template_content;
