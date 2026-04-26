-- Fix labels if client encoding mangled Chinese (ASCII-safe)
SET NAMES utf8mb4;
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('E8B4A2E58AA1E7BB9FE8AEA1') USING utf8mb4) WHERE path = 'analysis' AND menu_type = 'M';
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('E588A9E6B6A6E7BB9FE8AEA1') USING utf8mb4) WHERE path = 'financeProfit' AND menu_type = 'C';
UPDATE sys_menu SET menu_name = CONVERT(UNHEX('E6B688E8B4B9E6988EE7BB86') USING utf8mb4) WHERE path = 'financeBalanceLog' AND menu_type = 'C';
