-- After Phase2 API test, E2E_TSK_REVIEW_001 may become status 8 (escalated).
-- Run this to reset it to status 5 so "escalate" can be tested again without full seed.
SET NAMES utf8mb4;

UPDATE sms_send_task
SET status = '5', update_time = NOW()
WHERE task_no = 'E2E_TSK_REVIEW_001'
  AND del_flag = '0';

SELECT ROW_COUNT() AS rows_updated;
