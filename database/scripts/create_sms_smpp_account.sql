-- 客户 SMPP 外放账号（与 HTTP AppId/AppSecret 独立）
CREATE TABLE IF NOT EXISTS `sms_smpp_account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '所属用户',
  `system_id` varchar(32) NOT NULL COMMENT 'SMPP system_id（登录名）',
  `password` varchar(128) NOT NULL COMMENT 'SMPP 密码',
  `rate_limit` int DEFAULT '100' COMMENT '每分钟最大条数，0表示不限制',
  `sale_price` decimal(20,4) DEFAULT NULL COMMENT '售价(元/条)',
  `channel_id` bigint DEFAULT NULL COMMENT '默认发送通道ID',
  `status` char(1) DEFAULT '0' COMMENT '0启用 1停用',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(64) DEFAULT '',
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(64) DEFAULT '',
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_smpp_system_id` (`system_id`),
  KEY `idx_smpp_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='客户SMPP外放账号';
