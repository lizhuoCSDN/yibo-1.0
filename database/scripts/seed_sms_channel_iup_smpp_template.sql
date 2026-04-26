-- 将上游 SMPP（ESME 连 SMSC）登记到「通道管理」
-- 以下含 bind 真密，勿提交到公开仓库、勿外泄
SET NAMES utf8mb4;

INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  'IUP SMPP 173.245.95.66:8001',
  'iup_173_245_95_66_8001',
  '{"connectorType":"smpp","smppProvider":"laaffic","host":"173.245.95.66","port":8001,"systemId":"cs_iupdjw","password":"5VUISnm8","cps":50,"bindTimeoutMs":25000}',
  0, '0', 'admin', NOW(), 'IUP 线路：子户发信前需在「新户-线路分配」中分配并启用。'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sms_channel
  WHERE channel_code = 'iup_173_245_95_66_8001' AND (del_flag IS NULL OR del_flag = '0')
);

UPDATE sms_channel
SET config = '{"connectorType":"smpp","smppProvider":"laaffic","host":"173.245.95.66","port":8001,"systemId":"cs_iupdjw","password":"5VUISnm8","cps":50,"bindTimeoutMs":25000}', remark = 'IUP 线路：子户发信前需在「新户-线路分配」中分配并启用。'
WHERE channel_code = 'iup_173_245_95_66_8001' AND (del_flag IS NULL OR del_flag = '0');

SELECT 'seed_sms_channel_iup_smpp_template: done' AS result;
