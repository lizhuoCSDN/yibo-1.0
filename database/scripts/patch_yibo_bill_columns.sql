-- 修复: Unknown column 'st.bill_unit_price'（SmsSendTaskMapper 等依赖 sms_send_task.bill_unit_price）
-- 可重复执行：已存在列时不会重复 ADD
--
-- 命令行示例（按你本机改密码/用户）:
--   mysql -h 127.0.0.1 -P 3306 -u root -p yibo < database/scripts/patch_yibo_bill_columns.sql
-- 客户端: 先 USE yibo; 再执行本文件全文

USE yibo;

-- sms_send_task.bill_unit_price
SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'yibo' AND TABLE_NAME = 'sms_send_task' AND COLUMN_NAME = 'bill_unit_price';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_send_task ADD COLUMN bill_unit_price DECIMAL(20,4) DEFAULT NULL COMMENT ''外放对客单条短信售价(元/条)'' AFTER finish_time',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- sms_balance_log.amount（同批外放/金额能力；缺列时一并补上）
SELECT COUNT(*) INTO @c FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'yibo' AND TABLE_NAME = 'sms_balance_log' AND COLUMN_NAME = 'amount';
SET @sql = IF(@c = 0,
  'ALTER TABLE sms_balance_log ADD COLUMN amount DECIMAL(20,4) DEFAULT NULL COMMENT ''变动金额(元)'' AFTER change_count',
  'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
