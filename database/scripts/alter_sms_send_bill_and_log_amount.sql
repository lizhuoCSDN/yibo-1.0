-- 外放发信按任务维度记录单条「售价」；消费流水表增加元级 amount，与 change_count(条) 同时保留

SET @db = DATABASE();

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'bill_unit_price';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_task ADD COLUMN bill_unit_price DECIMAL(20,4) DEFAULT NULL COMMENT ''外放对客单条短信售价(元/条)'' AFTER finish_time',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'sms_balance_log' AND COLUMN_NAME = 'amount';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_balance_log ADD COLUMN amount DECIMAL(20,4) DEFAULT NULL COMMENT ''变动金额(元)'' AFTER change_count',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
