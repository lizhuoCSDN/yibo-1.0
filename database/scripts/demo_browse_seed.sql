-- 演示/浏览用种子数据（可重复执行：先清 DEMO_ 与 yibo_browse1）
SET NAMES utf8mb4;
SET @demo_u := (SELECT user_id FROM sys_user WHERE user_name = 'yibo_browse1' LIMIT 1);

-- ========== 清理旧 DEMO ==========
DELETE FROM sms_send_record WHERE task_id IN (SELECT id FROM (SELECT id FROM sms_send_task WHERE task_no LIKE 'DEMO%') t);
DELETE FROM sms_send_task WHERE task_no LIKE 'DEMO%';

DELETE c FROM sms_contact c
INNER JOIN sms_contact_group g ON c.group_id = g.id
WHERE g.group_name = 'DEMO_通讯录组';

DELETE FROM sms_contact_group WHERE group_name = 'DEMO_通讯录组';

DELETE FROM sms_tech_assist WHERE create_by = 'DEMO' OR ref_summary LIKE 'DEMO%';

DELETE FROM sms_balance_log WHERE remark LIKE 'DEMO%';

DELETE uc FROM sms_user_channel uc
WHERE @demo_u IS NOT NULL AND uc.user_id = @demo_u;

DELETE FROM sms_user_balance WHERE @demo_u IS NOT NULL AND user_id = @demo_u;

DELETE FROM sys_user_role WHERE @demo_u IS NOT NULL AND user_id = @demo_u;

DELETE FROM sys_user WHERE user_name = 'yibo_browse1';

-- ========== 通道健康（智能路由表）==========
INSERT INTO sms_channel_health (channel_id, success_count, fail_count, total_count, success_rate, avg_response_ms, circuit_state, weight, priority, window_start, create_time)
SELECT 1, 1280, 24, 1304, 98.20, 95, '0', 100, 0, NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sms_channel_health h WHERE h.channel_id = 1);
UPDATE sms_channel_health SET success_count = 1280, fail_count = 24, total_count = 1304, success_rate = 98.20, avg_response_ms = 95, circuit_state = '0' WHERE channel_id = 1;

-- ========== 管理员：余额 + 线路池 ==========
INSERT INTO sms_user_balance (user_id, parent_id, balance, total_used, status, create_by, create_time)
VALUES (1, 1, 999999.00, 0.00, '0', 'admin', NOW())
ON DUPLICATE KEY UPDATE balance = GREATEST(IFNULL(balance, 0), 500000.00), status = '0';

DELETE FROM sms_user_channel WHERE user_id = 1 AND channel_id = 1;
INSERT INTO sms_user_channel (user_id, channel_id, price, allot_count, used_count, enabled, create_by, create_time, remark, success_rate_min, success_rate_max)
VALUES (1, 1, 0.0300, 500000, 0, '1', 'admin', NOW(), 'DEMO: 管理端线路池', 40.00, 95.00);

-- ========== 子账户（密码与 admin 相同，便于登录）==========
SET @admin_pwd = (SELECT u.password FROM sys_user u WHERE u.user_id = 1 LIMIT 1);
INSERT INTO sys_user (dept_id, user_name, nick_name, phonenumber, password, user_type, status, del_flag, create_by, create_time, remark)
VALUES (
  103,
  'yibo_browse1',
  'DEMO子账户',
  '13900001234',
  @admin_pwd,
  '00',
  '0',
  '0',
  'admin',
  NOW(),
  'DEMO 演示数据，可删 yibo_browse1 重跑本脚本'
);
SET @uid = LAST_INSERT_ID();

INSERT INTO sys_user_role (user_id, role_id) VALUES (@uid, 2);

INSERT INTO sms_user_balance (user_id, parent_id, balance, total_used, status, create_by, create_time)
VALUES (@uid, 1, 50000.00, 0.00, '0', 'admin', NOW());

-- 子户：从上级池扣 20000（与上面 admin 500000 一致，admin 改 480000）
INSERT INTO sms_user_channel (user_id, channel_id, price, allot_count, used_count, enabled, create_by, create_time, remark, success_rate_min, success_rate_max)
VALUES (@uid, 1, 0.0800, 20000, 500, '1', 'admin', NOW(), 'DEMO: 子户线路 60~85%% 模拟', 60.00, 85.00);

UPDATE sms_user_channel SET allot_count = 480000 WHERE user_id = 1 AND channel_id = 1;

-- ========== 消费流水示例 ==========
INSERT INTO sms_balance_log (user_id, channel_id, change_type, change_count, balance_before, balance_after, create_time, create_by, remark) VALUES
(1, 1, '3', 100, 100000.00, 99900.00, DATE_SUB(NOW(), INTERVAL 2 DAY), 'admin', 'DEMO: 消费扣费'),
(1, NULL, '1', 5000, 90000.00, 95000.00, DATE_SUB(NOW(), INTERVAL 1 DAY), 'admin', 'DEMO: 充值');

-- ========== 短信模板 / 敏感词 ==========
INSERT INTO sms_template (template_name, template_content, user_id, status, create_by, create_time, del_flag) VALUES
('DEMO-活动通知', '【演示】{phone} 您好，活动已开启，回T退订。', 1, '0', 'admin', NOW(), '0'),
('DEMO-物流提醒', '【演示】您的包裹已发出。', 1, '0', 'admin', NOW(), '0');

INSERT INTO sms_keyword (keyword, category, match_type, status, create_by, create_time) VALUES
('demo_test_word', '默认', '0', '0', 'admin', NOW());

-- ========== 发送任务（不同状态）==========
SET @ch := (SELECT channel_name FROM sms_channel WHERE id = 1 LIMIT 1);
INSERT INTO sms_send_task (task_no, user_id, user_name, channel_id, channel_name, sms_content, total_count, success_count, fail_count, pending_count, status, timing_type, create_by, create_time, del_flag, phone_source, remark) VALUES
('DEMO_T001', 1, 'admin', 1, @ch, '【DEMO】待发送/排队中', 200, 0, 0, 200, '0', 'now', 'admin', NOW(), '0', 'manual', 'DEMO'),
('DEMO_T002', 1, 'admin', 1, @ch, '【DEMO】已发送完成', 100, 96, 4, 0, '2', 'now', 'admin', DATE_SUB(NOW(), INTERVAL 2 HOUR), '0', 'manual', 'DEMO'),
('DEMO_T003', 1, 'admin', 1, @ch, '【DEMO】内容待审核(若菜单有审核流)', 15, 0, 0, 15, '5', 'now', 'admin', NOW(), '0', 'manual', 'DEMO 审核'),
('DEMO_T004', @uid, 'yibo_browse1', 1, @ch, '【DEMO】子账户任务', 30, 18, 7, 5, '2', 'now', 'yibo_browse1', NOW(), '0', 'manual', 'DEMO');

-- ========== 技术协助 / 联系人 ==========
INSERT INTO sms_tech_assist (page_code, page_label, ref_id, ref_summary, question, status, pending_level, del_flag, create_by, create_time)
VALUES ('channel', 'DEMO-通道', 1, 'DEMO/巴西pt', 'DEMO: 请协助看通道质量', '0', 1, '0', 'admin', NOW());

INSERT INTO sms_contact_group (group_name, user_id, contact_count, create_by, del_flag) VALUES ('DEMO_通讯录组', 1, 2, 'admin', '0');
SET @gid := LAST_INSERT_ID();
UPDATE sms_contact_group SET contact_count = 2 WHERE id = @gid;
INSERT INTO sms_contact (group_id, phone_number, contact_name, user_id, del_flag) VALUES
(@gid, '8613900011111', '演示甲', 1, '0'),
(@gid, '8613900011112', '演示乙', 1, '0');

SELECT 'demo seed ok' AS result,
  @uid AS sub_user_id,
  (SELECT allot_count FROM sms_user_channel WHERE user_id = 1 AND channel_id = 1) AS admin_allot,
  (SELECT allot_count FROM sms_user_channel WHERE user_id = @uid AND channel_id = 1) AS sub_allot;
