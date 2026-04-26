-- 线路分配：成功率区间（两列均非空时，发送任务按该区间模拟成功/失败/待发送，见 SmsSendEngine）
ALTER TABLE sms_user_channel
  ADD COLUMN success_rate_min DECIMAL(5,2) DEFAULT NULL COMMENT '模拟成功率下限%%' AFTER remark,
  ADD COLUMN success_rate_max DECIMAL(5,2) DEFAULT NULL COMMENT '模拟成功率上限%%' AFTER success_rate_min;
