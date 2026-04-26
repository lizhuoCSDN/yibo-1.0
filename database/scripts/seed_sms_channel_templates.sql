-- 在「通道管理」列表中预置 3 条通道模板（若不存在则插入）
-- 对接逻辑已在程序里；列表数据来自本表，不会自动生成，需执行本脚本或后台「新增」
-- 插入后请编辑各通道，补全 AppId/Key/Secret 或 SMPP 用户名密码等
SET NAMES utf8mb4;

-- 1) Laaffic HTTP API v3
INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  'Laaffic（HTTP v3）',
  'laaffic_api',
  '{"connectorType":"api","apiProvider":"laaffic","sendUrl":"https://api.laaffic.com/v3/sendSms","balanceUrl":"https://api.laaffic.com/v3/getBalance","appId":"","appKey":"","appSecret":""}',
  0, '0', 'admin', NOW(), '预置：请补全 AppId、Api-Key、API Secret 后保存并启用。'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sms_channel WHERE channel_code = 'laaffic_api' AND (del_flag IS NULL OR del_flag = '0'));

-- 2) Laaffic SMPP
INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  'Laaffic（SMPP）',
  'laaffic_smpp',
  '{"connectorType":"smpp","smppProvider":"laaffic","host":"smpp.laaffic.com","port":8001,"systemId":"","password":"","cps":50}',
  0, '0', 'admin', NOW(), '预置：bind 用户名为 API Key、密码为 API Secret。请在客户端或控制台获取后保存。'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sms_channel WHERE channel_code = 'laaffic_smpp' AND (del_flag IS NULL OR del_flag = '0'));

-- 3) 通用 SMPP（自定义上游主机）
INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  'SMPP（通用）',
  'smpp_generic',
  '{"connectorType":"smpp","host":"","port":2775,"systemId":"","password":"","cps":50}',
  0, '0', 'admin', NOW(), '预置：请填写您的 SMSC 主机、端口、系统号、密码。线路选「通用 SMPP」。'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sms_channel WHERE channel_code = 'smpp_generic' AND (del_flag IS NULL OR del_flag = '0'));

SELECT 'seed_sms_channel_templates: done' AS result;
