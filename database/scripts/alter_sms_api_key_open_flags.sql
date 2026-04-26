-- 外放接口：HTTP 开放 / SMPP 开放
-- 执行一次即可；若列已存在会报错，可忽略或手动注释掉对应行

ALTER TABLE sms_api_key ADD COLUMN api_open char(1) NOT NULL DEFAULT '1' COMMENT 'HTTP外放API:1开放0关闭' AFTER status;
ALTER TABLE sms_api_key ADD COLUMN smpp_open char(1) NOT NULL DEFAULT '1' COMMENT 'SMPP开放:1开放0关闭' AFTER api_open;
