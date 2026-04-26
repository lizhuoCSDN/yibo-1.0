-- Multi-rule channel alert JSON (optional; takes precedence over alert_channel_ids)
ALTER TABLE `sms_balance_alert_config`
  ADD COLUMN `alert_rules_json` text DEFAULT NULL COMMENT 'alert rules JSON (rules+lastByUc)' AFTER `cooldown_minutes`;
