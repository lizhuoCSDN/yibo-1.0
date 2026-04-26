-- Expand SMPP login name length for IP_userId style system_id
-- Safe to re-run: MODIFY keeps data if widening.
ALTER TABLE `sms_smpp_account` MODIFY COLUMN `system_id` varchar(64) NOT NULL COMMENT 'SMPP system_id (login)';
