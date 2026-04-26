-- If you created wallet_usdt_tx with UNIQUE(tx_hash), drop it so one tx can hold multiple TRC20 transfers.
-- Safe to run once; ignore error if index already absent.
SET @exist := (SELECT COUNT(1) FROM information_schema.statistics
  WHERE table_schema = DATABASE() AND table_name = 'wallet_usdt_tx' AND index_name = 'uk_wallet_tx_hash');
SET @sql := IF(@exist > 0, 'ALTER TABLE wallet_usdt_tx DROP INDEX uk_wallet_tx_hash', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
