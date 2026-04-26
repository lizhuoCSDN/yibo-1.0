-- Channel: country/region label for routing and display
ALTER TABLE sms_channel
  ADD COLUMN country varchar(128) NULL DEFAULT NULL COMMENT 'country or region' AFTER channel_code;
