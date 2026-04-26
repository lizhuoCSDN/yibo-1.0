-- 内容审核：待审任务由哪个上级处理（子账号命中小词时指向直接上级；提交复核时指向更上级）
ALTER TABLE sms_send_task
  ADD COLUMN review_owner_id BIGINT NULL COMMENT '待处理审核的账户ID（上级/更上级）' AFTER user_name;

-- 给审核列表用（可选）
-- ALTER TABLE sms_send_task ADD KEY idx_sms_task_review_owner (review_owner_id, status);
