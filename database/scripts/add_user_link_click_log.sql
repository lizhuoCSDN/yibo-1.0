-- User link click log (daily/hourly charts)
CREATE TABLE IF NOT EXISTS `user_link_click_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_link_id` bigint NOT NULL,
  `click_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_link_id` (`user_link_id`),
  KEY `idx_click_time` (`click_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
