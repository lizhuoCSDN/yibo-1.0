-- Parent path=analysis (M) -> display name 财务统计; two children: financeBalanceLog, financeProfit
-- Chinese labels applied via UTF-8 hex (safe for any mysql client code page)
SET NAMES utf8mb4;

SET @analysis_id := (
  SELECT menu_id FROM sys_menu WHERE path = 'analysis' AND menu_type = 'M' LIMIT 1
);

UPDATE sys_menu
SET menu_name = CONVERT(UNHEX('E8B4A2E58AA1E7BB9FE8AEA1') USING utf8mb4)
WHERE menu_id = @analysis_id AND @analysis_id IS NOT NULL;

UPDATE sys_menu
SET menu_name = CONVERT(UNHEX('E588A9E6B6A6E7BB9FE8AEA1') USING utf8mb4),
    path = 'financeProfit',
    component = 'business/finance/profit',
    order_num = 2
WHERE path = 'finance'
  AND menu_type = 'C'
  AND parent_id = @analysis_id
  AND @analysis_id IS NOT NULL;

INSERT INTO sys_menu (
  menu_name, parent_id, order_num, path, component, is_frame, menu_type,
  visible, status, perms, icon, create_by, create_time, remark
)
SELECT
  '', @analysis_id, 1, 'financeBalanceLog', 'business/finance/balanceLog', 1, 'C',
  '0', '0', 'business:finance:list', 'list', 'admin', NOW(), ''
FROM DUAL
WHERE @analysis_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sys_menu WHERE parent_id = @analysis_id AND path = 'financeBalanceLog'
  );

SET @bal_id := (
  SELECT menu_id FROM sys_menu
  WHERE parent_id = @analysis_id AND path = 'financeBalanceLog' AND menu_type = 'C'
  LIMIT 1
);

SET @profit_id := (
  SELECT menu_id FROM sys_menu
  WHERE parent_id = @analysis_id AND path = 'financeProfit' AND menu_type = 'C'
  LIMIT 1
);

INSERT IGNORE INTO sys_role_menu (role_id, menu_id)
SELECT DISTINCT r.role_id, @bal_id
FROM sys_role_menu r
WHERE @bal_id IS NOT NULL
  AND @profit_id IS NOT NULL
  AND r.menu_id = @profit_id;

UPDATE sys_menu SET menu_name = CONVERT(UNHEX('E6B688E8B4B9E6988EE7BB86') USING utf8mb4),
  remark = CONVERT(UNHEX('E4BD99E9A29DE58F98E58AA8E6988EE7BB86') USING utf8mb4)
WHERE path = 'financeBalanceLog' AND menu_type = 'C';
