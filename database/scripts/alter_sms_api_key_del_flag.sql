-- �߼�ɾ����־���� RuoYi Լ��һ�£�0 ������2 ɾ����
-- �����Ѵ��ڻᱨ�����ɺ��Ի�ע�͵����ļ���ִ��

ALTER TABLE sms_api_key ADD COLUMN del_flag CHAR(1) NOT NULL DEFAULT '0' COMMENT 'ɾ����־:0���� 2ɾ��' AFTER remark;
