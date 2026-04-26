-- USDT wallet analysis: bind + tx (standalone module)
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS wallet_usdt_bind (
  id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'PK',
  account_code  VARCHAR(64)  NOT NULL COMMENT 'unique account id',
  usdt_address  VARCHAR(128) NOT NULL COMMENT 'USDT address',
  chain_type    VARCHAR(16)  NOT NULL DEFAULT 'TRC20' COMMENT 'TRC20/ERC20',
  bind_role     VARCHAR(32)  NOT NULL DEFAULT 'CUSTOMER' COMMENT '用户类型 INTERNAL/同行 COMPETITOR/客户 CUSTOMER',
  remark        VARCHAR(500) DEFAULT NULL COMMENT 'remark',
  create_by     VARCHAR(64)  DEFAULT NULL,
  create_time   DATETIME     DEFAULT NULL,
  update_by     VARCHAR(64)  DEFAULT NULL,
  update_time   DATETIME     DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_wallet_bind_account (account_code),
  UNIQUE KEY uk_wallet_bind_address (usdt_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='wallet_usdt_bind';

CREATE TABLE IF NOT EXISTS wallet_usdt_tx (
  id           BIGINT        NOT NULL AUTO_INCREMENT COMMENT 'PK',
  tx_hash      VARCHAR(128)  NOT NULL COMMENT 'tx hash',
  from_address VARCHAR(128)  NOT NULL COMMENT 'from',
  to_address   VARCHAR(128)  NOT NULL COMMENT 'to',
  amount       DECIMAL(36,18) NOT NULL COMMENT 'amount',
  tx_time      DATETIME      DEFAULT NULL COMMENT 'tx time',
  remark       VARCHAR(500)  DEFAULT NULL COMMENT 'remark',
  create_by    VARCHAR(64)   DEFAULT NULL,
  create_time  DATETIME      DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_wallet_tx_hash (tx_hash),
  KEY idx_wallet_tx_from (from_address),
  KEY idx_wallet_tx_to (to_address),
  KEY idx_wallet_tx_time (tx_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='wallet_usdt_tx';
