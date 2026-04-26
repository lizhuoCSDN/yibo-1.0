-- 域名分配给下级使用 / 回收后禁用
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS domain_user_grant (
  id          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  domain_id   BIGINT      NOT NULL COMMENT '域名表 ID',
  user_id     BIGINT      NOT NULL COMMENT '被分配用户 sys_user.user_id',
  status      CHAR(1)     NOT NULL DEFAULT '0' COMMENT '0=有效(可使用) 1=已回收(禁用)',
  create_by   VARCHAR(64)          DEFAULT NULL COMMENT '操作人(分配人)',
  create_time DATETIME              DEFAULT NULL,
  update_time DATETIME              DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_domain_user (domain_id, user_id),
  KEY idx_dug_user (user_id, status),
  KEY idx_dug_domain (domain_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='域名分配给下级与回收';
