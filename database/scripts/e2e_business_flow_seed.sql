-- E2E business flow seed (idempotent for markers E2E_* / yibo_e2e_test)
-- Run: mysql -u root -pPASSWORD --protocol=tcp -D yibo < e2e_business_flow_seed.sql
SET NAMES utf8mb4;

-- ========== cleanup ==========
DELETE FROM sms_send_task WHERE task_no IN ('E2E_TSK_REVIEW_001', 'E2E_TSK_REVIEW_002');

DELETE c FROM sms_contact c
INNER JOIN sms_contact_group g ON c.group_id = g.id
WHERE g.group_name = 'E2E_Contact_Group';

DELETE FROM sms_contact_group WHERE group_name = 'E2E_Contact_Group';

DELETE uc FROM sms_user_channel uc
INNER JOIN sys_user u ON uc.user_id = u.user_id
WHERE u.user_name = 'yibo_e2e_test';

DELETE b FROM sms_user_balance b
INNER JOIN sys_user u ON b.user_id = u.user_id
WHERE u.user_name = 'yibo_e2e_test';

DELETE FROM sys_user_role
WHERE user_id IN (SELECT user_id FROM (SELECT user_id FROM sys_user WHERE user_name = 'yibo_e2e_test') t);

DELETE FROM sys_user WHERE user_name = 'yibo_e2e_test';

DELETE FROM sms_channel_health
WHERE channel_id IN (SELECT id FROM (SELECT id FROM sms_channel WHERE channel_code = 'E2E_CH001') x);

DELETE FROM sms_channel WHERE channel_code = 'E2E_CH001';

-- ========== channel + health (智能路由 / 线路分配) ==========
INSERT INTO sms_channel (
  channel_name, channel_code, country, docking_method, total_count, cost_price, score, success_rate,
  status, del_flag, create_by, create_time, remark
) VALUES (
  'E2E Demo Channel', 'E2E_CH001', 'CN', 'api', 100000, 0.0100, 95.00, 99.00,
  0, '0', 'admin', NOW(), 'E2E seed channel'
);

SET @e2e_ch = LAST_INSERT_ID();

INSERT INTO sms_channel_health (
  channel_id, success_count, fail_count, total_count, success_rate, avg_response_ms,
  circuit_state, weight, priority, window_start, create_time
) VALUES (
  @e2e_ch, 10, 0, 10, 100.00, 120, '0', 100, 0, NOW(), NOW()
);

-- ========== sub user + balance + 线路分配 ==========
INSERT INTO sys_user (
  dept_id, user_name, nick_name, phonenumber, country, password, sex, status, del_flag, create_by, create_time, remark
) VALUES (
  101,
  'yibo_e2e_test',
  'E2E Sub User',
  '1380000E2E',
  'CN',
  (SELECT password FROM sys_user WHERE user_name = 'admin' LIMIT 1),
  '0',
  '0',
  '0',
  'admin',
  NOW(),
  'E2E seeded sub-account (same password as admin)'
);

SET @e2e_uid = LAST_INSERT_ID();

INSERT INTO sys_user_role (user_id, role_id) VALUES (@e2e_uid, 2);

INSERT INTO sms_user_balance (user_id, parent_id, balance, total_used, status, create_by, create_time)
VALUES (@e2e_uid, 1, 10000, 0, '0', 'admin', NOW());

INSERT INTO sms_user_channel (user_id, channel_id, price, allot_count, used_count, enabled, create_by, create_time, remark)
VALUES (@e2e_uid, @e2e_ch, 0.0500, 5000, 0, '1', 'admin', NOW(), 'E2E allocation');

-- ========== 内容审核待办 ==========
INSERT INTO sms_send_task (
  task_no, user_id, user_name, channel_id, channel_name, sms_content,
  original_url, domain_ids, total_count, success_count, fail_count, pending_count,
  status, timing_type, timing_time, create_by, create_time, del_flag, remark
) VALUES
(
  'E2E_TSK_REVIEW_001',
  1,
  'admin',
  @e2e_ch,
  'E2E Demo Channel',
  'E2E pending review: hello keyword-demo',
  '', '', 3, 0, 0, 3,
  '5', 'now', NULL,
  'admin', NOW(), '0',
  'hit: demo'
),
(
  'E2E_TSK_REVIEW_002',
  @e2e_uid,
  'yibo_e2e_test',
  @e2e_ch,
  'E2E Demo Channel',
  'E2E escalated sample (status 8)',
  '', '', 1, 0, 0, 1,
  '8', 'now', NULL,
  'admin', NOW(), '0',
  'escalated'
);

-- ========== 通讯录分组 + 号码 ==========
INSERT INTO sms_contact_group (group_name, user_id, contact_count, create_by, del_flag)
VALUES ('E2E_Contact_Group', 1, 2, 'admin', '0');

SET @e2e_gid = LAST_INSERT_ID();

INSERT INTO sms_contact (group_id, phone_number, contact_name, user_id, del_flag) VALUES
(@e2e_gid, '8613800000001', 'E2E A', 1, '0'),
(@e2e_gid, '8613800000000002', 'E2E B', 1, '0');

SELECT 'e2e seed done' AS result, @e2e_uid AS e2e_user_id, @e2e_ch AS e2e_channel_id;
