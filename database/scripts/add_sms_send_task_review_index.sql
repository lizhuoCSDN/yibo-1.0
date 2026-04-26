-- 内容审核列表加速：del_flag + status + 排序字段
-- 在 yibo 库执行一次；若提示 Duplicate key name 'idx_sms_send_task_review_list' 则说明已存在，可忽略

SET @exist := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'sms_send_task'
    AND index_name = 'idx_sms_send_task_review_list'
);

SET @sql := IF(
  @exist = 0,
  'CREATE INDEX idx_sms_send_task_review_list ON sms_send_task (del_flag, status, create_time)',
  'SELECT ''index idx_sms_send_task_review_list already exists'' AS msg'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
