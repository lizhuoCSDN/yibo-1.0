-- 通道路由热路径与列表相关索引（在业务库上执行前请用 EXPLAIN 对 selectRoutableChannelsByUserId 等语句确认本库是否已存在等价索引，避免重复创建）
-- MySQL 8+

-- sms_user_channel：按子户+启用 筛线路（可路由子查询）
-- 若表上仅有 user_id 单列索引、且 enabled 选择性强，可尝试：
-- CREATE INDEX idx_uc_user_enabled ON sms_user_channel (user_id, enabled);

-- sms_channel：启用且未删的通道
-- CREATE INDEX idx_sc_status_delflag ON sms_channel (status, del_flag);

-- sms_channel_health：按 channel_id 联表；若主键/唯一即 channel_id 则通常无需再建
-- 若需按 circuit_state 筛可选（当前多数场景 left join 后应用层已筛）：
-- CREATE INDEX idx_sch_circuit ON sms_channel_health (channel_id, circuit_state);
