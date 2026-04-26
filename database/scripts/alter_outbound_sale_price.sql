-- API 外放、SMPP 外放：展示/维护对客「售价」（元/条，可空表示未设）
-- 在已有环境执行一次即可。

ALTER TABLE sms_api_key
  ADD COLUMN sale_price DECIMAL(20,4) DEFAULT NULL COMMENT '售价(元/条)' AFTER rate_limit;

ALTER TABLE sms_smpp_account
  ADD COLUMN sale_price DECIMAL(20,4) DEFAULT NULL COMMENT '售价(元/条)' AFTER rate_limit;
