-- Address bind role: INTERNAL=org internal, CUSTOMER=customer, COMPETITOR=competitor
SET NAMES utf8mb4;

ALTER TABLE wallet_usdt_bind
  ADD COLUMN bind_role VARCHAR(32) NOT NULL DEFAULT 'CUSTOMER'
  COMMENT 'INTERNAL|CUSTOMER|COMPETITOR'
  AFTER chain_type;
