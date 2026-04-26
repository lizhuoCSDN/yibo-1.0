-- 国际短信平台《API 对接说明 v3.2》OpenAPI v2：ta-sms 路径 (submittal/balance + ta-version: v2)，非云发 JSON 体。
-- 已预填 apiKey；taBaseUrl、username(通道号) 向供应商索取后在「通道管理 — 国际短信 (OpenAPI v2)」中补全并保存。
SET NAMES utf8mb4;

INSERT INTO sms_channel (channel_name, channel_code, config, status, del_flag, create_by, create_time, remark)
SELECT
  '国际短信(ta-sms v2·待补域名/通道号)',
  'new_supplier_api_pdf',
  '{"connectorType":"api","apiProvider":"ta_sms_openapi","httpAdapter":"ta_sms_openapi_v2","taBaseUrl":"","username":"","apiKey":"8CG1HbLkoIi0Htulg8eVTsJ5kGrTxlHf","signType":"MD5","upstreamSchema":1}',
  0, '0', 'admin', NOW(), '在后台填写 taBaseUrl、通道编号。子户发信前在「新户-线路分配」中启用。'
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM sms_channel
  WHERE channel_code = 'new_supplier_api_pdf' AND (del_flag IS NULL OR del_flag = '0')
);

UPDATE sms_channel
SET
  config = '{"connectorType":"api","apiProvider":"ta_sms_openapi","httpAdapter":"ta_sms_openapi_v2","taBaseUrl":"","username":"","apiKey":"8CG1HbLkoIi0Htulg8eVTsJ5kGrTxlHf","signType":"MD5","upstreamSchema":1}',
  remark = '在后台填写 taBaseUrl、通道编号。国际短信 OpenAPI v2 对接。'
WHERE channel_code = 'new_supplier_api_pdf' AND (del_flag IS NULL OR del_flag = '0');

SELECT 'seed_sms_channel_new_vendor_from_pdf: done' AS result;
