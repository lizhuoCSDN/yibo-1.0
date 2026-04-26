-- Content review fake data: status 5 (initial) + status 8 (escalated)
-- Run: mysql -u USER -p --default-character-set=utf8mb4 YOUR_DB < seed_content_review_fake.sql
-- Idempotent: deletes by task_no then inserts

SET NAMES utf8mb4;

DELETE FROM sms_send_task WHERE task_no IN ('T_FAKE_REVIEW_001', 'T_FAKE_REVIEW_002');

INSERT INTO sms_send_task (
  task_no, user_id, user_name, channel_id, channel_name, sms_content,
  original_url, domain_ids, total_count, success_count, fail_count, pending_count,
  status, timing_type, timing_time, start_time, finish_time,
  create_by, create_time, update_by, update_time, del_flag, remark
) VALUES
(
  'T_FAKE_REVIEW_001',
  1,
  'admin',
  NULL,
  'demo-channel',
  '[FAKE-001] Initial review task. Column "环节" = 初审. Buttons: Pass / Re-review / Reject.',
  '',
  '',
  2,
  0,
  0,
  2,
  '5',
  'now',
  NULL,
  NULL,
  NULL,
  'admin',
  NOW(),
  NULL,
  NOW(),
  '0',
  'hit: demo-keyword-a, demo-keyword-b'
),
(
  'T_FAKE_REVIEW_002',
  1,
  'admin',
  NULL,
  'demo-channel',
  '[FAKE-002] Escalated task. Column "环节" = 上级复审. Re-review button disabled.',
  '',
  '',
  5,
  0,
  0,
  5,
  '8',
  'now',
  NULL,
  NULL,
  NULL,
  'admin',
  NOW(),
  NULL,
  NOW(),
  '0',
  'hit: demo-keyword-c'
);
