-- ��ʷ��ʹ�� ip_whitelist�������� Mapper ʹ�� whitelist_ips��ͳһΪ whitelist_ips�����ݱ�����
-- ���������� whitelist_ips �ᱨ�����ɺ���

ALTER TABLE sms_api_key CHANGE COLUMN ip_whitelist whitelist_ips VARCHAR(500) DEFAULT NULL COMMENT 'IP�����������ŷָ�';
