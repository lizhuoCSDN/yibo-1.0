-- 将上游 SMPP 登记到「通道管理」（183.178.45.166:7890，login=鉴权名）
-- 以下含 bind 真密，勿提交到公开仓库、勿外泄
SET NAMES utf8mb4;

INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  'SMPP 183.178.45.166:7890',
  'smpp_183_178_45_166_7890',
  '{"connectorType":"smpp","host":"183.178.45.166","port":7890,"systemId":"kRQogH","password":"FCJsYM7U","cps":50,"bindTimeoutMs":25000}',
  0, '0', 'admin', NOW(), '通用 SMPP；子户发信前需在「新户-线路分配」中分配本通道。'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sms_channel
  WHERE channel_code = 'smpp_183_178_45_166_7890' AND (del_flag IS NULL OR del_flag = '0')
);

UPDATE sms_channel
SET config = '{"connectorType":"smpp","host":"183.178.45.166","port":7890,"systemId":"kRQogH","password":"FCJsYM7U","cps":50,"bindTimeoutMs":25000}', remark = '通用 SMPP；子户发信前需在「新户-线路分配」中分配本通道。'
WHERE channel_code = 'smpp_183_178_45_166_7890' AND (del_flag IS NULL OR del_flag = '0');

SELECT 'seed_sms_channel_183_178_45_166_7890_template: done' AS result;
