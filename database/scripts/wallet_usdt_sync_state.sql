-- TRC20 链上流水同步缓存：命中 TTL 内不重复请求 TronGrid
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS wallet_usdt_sync_state (
  usdt_address VARCHAR(128) NOT NULL COMMENT 'TRON 地址',
  last_sync_at DATETIME NOT NULL COMMENT '上次全量同步时间',
  row_count INT NOT NULL DEFAULT 0 COMMENT '同步写入笔数',
  update_time DATETIME DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (usdt_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='wallet_usdt_sync_state';
